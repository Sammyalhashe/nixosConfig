#!/usr/bin/env nix-shell
#!nix-shell -i nu -p nushell sops

# CACHIX_AUTH_TOKEN comes from the systemd service's EnvironmentFile in
# production; this is only a fallback for manual/devshell runs.
def ensure-cachix-token [] {
  if ($env.CACHIX_AUTH_TOKEN? | is-empty) {
    let token = (sops -d --extract '["cachix_token"]' secrets.yaml | str trim)
    if ($token | is-empty) {
      print -e "Error: Could not retrieve CACHIX_AUTH_TOKEN from secrets.yaml"
      exit 1
    }
    $env.CACHIX_AUTH_TOKEN = $token
  }
}

def get-flake-hosts [flake: string] {
  nix eval --json $"($flake)#nixosConfigurations" --apply builtins.attrNames
  | from json
}

def unstable-rev [] {
  git ls-remote git@github.com:Sammyalhashe/nixosConfig refs/heads/unstable
  | lines
  | get 0
  | split row "\t"
  | get 0
}

def push-host [flake: string, host: string] {
  print $"Building ($host) system configuration..."
  let out_path = (
    nix build $"($flake)#nixosConfigurations.($host).config.system.build.toplevel" --no-link --print-out-paths
    | lines
    | get 0
  )
  if ($out_path | is-empty) {
    error make { msg: $"build produced no output for ($host)" }
  }
  print $"Pushing ($out_path) to cachix..."
  cachix push starllama $out_path
  $out_path
}

# try/catch is a closure boundary in nushell, which forbids capturing the
# outer `mut results` from main -- so failures are reported as a plain
# record here instead of by mutating shared state inside the catch arm.
def try-push [flake: string, host: string] {
  try {
    let out_path = (push-host $flake $host)
    { host: $host, status: "ok", path: $out_path }
  } catch { |err|
    print -e $"($host) failed: ($err.msg)"
    { host: $host, status: "failed", path: "" }
  }
}

def main [host?: string, --remote] {
  ensure-cachix-token

  # Resolved once and reused for last-rev below -- calling unstable-rev again
  # at the end would record whatever unstable moved to mid-run, not the rev
  # that was actually built.
  mut rev = ""

  let flake = if $remote {
    $rev = (unstable-rev)
    let state_dir = ($env.STATE_DIRECTORY? | default "")
    if not ($state_dir | is-empty) {
      let last_rev_file = ($state_dir | path join "last-rev")
      if ($last_rev_file | path exists) and ((open $last_rev_file | str trim) == $rev) {
        print $"unstable is unchanged at ($rev), nothing to do"
        exit 0
      }
    }
    $"git+ssh://git@github.com/Sammyalhashe/nixosConfig?ref=unstable&rev=($rev)"
  } else {
    "."
  }

  let hosts = if ($host | is-empty) { get-flake-hosts $flake } else { [$host] }

  mut results = []
  for h in $hosts {
    print $"=== ($h) ==="
    let r = (try-push $flake $h)
    $results = ($results | append $r)
  }

  print "\nSummary:"
  print ($results | select host status)

  let failed = ($results | where status == "failed")

  if $remote and ($failed | is-empty) {
    let state_dir = ($env.STATE_DIRECTORY? | default "")
    if not ($state_dir | is-empty) {
      $rev | save -f ($state_dir | path join "last-rev")
    }
  }

  if not ($failed | is-empty) {
    exit 1
  }
}

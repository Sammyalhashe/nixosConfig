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
  let result = (nix eval --json $"($flake)#nixosConfigurations" --apply builtins.attrNames | complete)
  complete-or-error "evaluating NixOS hosts" $result | from json
}

def get-deploy-hosts [flake: string] {
  let result = (nix eval --json $"($flake)#deploy.nodes" --apply builtins.attrNames | complete)
  complete-or-error "evaluating deploy hosts" $result | from json
}

def complete-or-error [action: string, result: record] {
  if $result.exit_code != 0 {
    let detail = ($result.stderr | str trim)
    let message = if ($detail | is-empty) {
      $"($action) failed with exit code ($result.exit_code)"
    } else {
      $"($action) failed: ($detail)"
    }
    error make { msg: $message }
  }
  $result.stdout
}

def unstable-rev [] {
  let result = (git ls-remote git@github.com:Sammyalhashe/nixosConfig refs/heads/unstable | complete)
  complete-or-error "resolving unstable" $result
  | lines
  | get 0
  | split row "\t"
  | get 0
}

def push-host [flake: string, host: string] {
  print $"Building ($host) system configuration..."
  let build_result = (
    nix build $"($flake)#nixosConfigurations.($host).config.system.build.toplevel" --no-link --print-out-paths
    | complete
  )
  let out_path = (complete-or-error $"building ($host)" $build_result | lines | get 0)
  if ($out_path | is-empty) {
    error make { msg: $"build produced no output for ($host)" }
  }
  print $"Pushing ($out_path) to cachix..."
  let push_result = (cachix push starllama $out_path | complete)
  complete-or-error $"pushing ($host) to Cachix" $push_result | ignore
  $out_path
}

def advance-deployed [state_dir: string, rev: string] {
  let repo = ($state_dir | path join "repo.git")
  if not ($repo | path exists) {
    print $"Creating bare repository at ($repo)"
    let clone_result = (
      git clone --bare --filter=blob:none git@github.com:Sammyalhashe/nixosConfig.git $repo
      | complete
    )
    complete-or-error "creating the bare repository" $clone_result | ignore
  }

  let fetch_result = (git -C $repo fetch origin $rev | complete)
  complete-or-error $"fetching ($rev)" $fetch_result | ignore

  let push_result = (git -C $repo push origin $"($rev):refs/heads/deployed" | complete)
  complete-or-error $"advancing deployed to ($rev)" $push_result | ignore
  print $"deployed now points to ($rev)"
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

def main [host?: string, --remote, --retry] {
  ensure-cachix-token

  # Resolved once and reused for last-rev below -- calling unstable-rev again
  # at the end would record whatever unstable moved to mid-run, not the rev
  # that was actually built.
  mut rev = ""
  mut state_dir = ""

  let flake = if $remote {
    $rev = (unstable-rev)
    $state_dir = ($env.STATE_DIRECTORY? | default "/var/lib/push-to-cachix")
    let last_rev_file = ($state_dir | path join "last-rev")
    if ($last_rev_file | path exists) and ((open $last_rev_file | str trim) == $rev) {
      print $"unstable is already fully pushed at ($rev), nothing to do"
      exit 0
    }
    let last_attempt_file = ($state_dir | path join "last-attempt")
    if not $retry and ($last_attempt_file | path exists) and ((open $last_attempt_file | str trim) == $rev) {
      print $"unstable was already attempted at ($rev), use --retry to try again"
      exit 0
    }
    $"git+ssh://git@github.com/Sammyalhashe/nixosConfig?ref=unstable&rev=($rev)"
  } else {
    "."
  }

  let flake_hosts = (get-flake-hosts $flake)
  let hosts = if ($host | is-empty) { $flake_hosts } else { [$host] }

  if $remote {
    $rev | save -f ($state_dir | path join "last-attempt")
  }

  mut results = []
  for h in $hosts {
    print $"=== ($h) ==="
    let r = (try-push $flake $h)
    $results = ($results | append $r)
  }

  print "\nSummary:"
  print ($results | select host status)

  let failed = ($results | where status == "failed")

  if $remote {
    let deploy_hosts = (get-deploy-hosts $flake)
    let successful_hosts = ($results | where status == "ok" | get host)
    let blocked_deploy_hosts = ($deploy_hosts | where { |name| $name not-in $successful_hosts })
    let incomplete_hosts = ($flake_hosts | where { |name| $name not-in $successful_hosts })

    if ($blocked_deploy_hosts | is-empty) {
      advance-deployed $state_dir $rev
    } else {
      print -e $"Not advancing deployed; required hosts did not succeed: ($blocked_deploy_hosts | str join ', ')"
    }

    if ($failed | is-empty) and ($incomplete_hosts | is-empty) {
      $rev | save -f ($state_dir | path join "last-rev")
    }
  }

  if not ($failed | is-empty) {
    exit 1
  }
}

#!/usr/bin/env nix-shell
#!nix-shell -i nu -p nushell sops

def get-nixosConfigurations [] {
  let metadata = nix flake show --json --quiet err> /dev/null | from json | get nixosConfigurations
  return $metadata
}

def push [host: string] {
  # 1. Handle the Cachix Auth Token
  if ($env | get -i CACHIX_AUTH_TOKEN | is-empty) {
      let token = (sops -d --extract '["cachix_token"]' secrets.yaml | str trim)
  
      if ($token | is-empty) {
          print -e "Error: Could not retrieve CACHIX_AUTH_TOKEN from secrets.yaml"
          exit 1
      }
  
      # In Nushell, we assign to the environment record directly
      $env.CACHIX_AUTH_TOKEN = $token
  }
  
  # 2. Build the system configuration
  print $"Building ($host) system configuration..."
  
  # We pipe directly to 'from json' instead of using jq
  let build_output = (
      nix build ."#nixosConfigurations.($host).config.system.build.toplevel --json"
      | from json
  )
  
  # Extract the output path from the first element of the resulting list
  let out_path = ($build_output | get 0.outputs.out)
  
  # 3. Validation and Pushing
  if ($out_path | is-empty) {
      print -e $"Error: Build failed or produced no output for ($host)."
      exit 1
  }
  
  print $"Pushing ($out_path) to cachix..."
  cachix push starllama $out_path
}

def main [] {
  get-nixosConfigurations | columns | par-each { |e| push ($e)}
}


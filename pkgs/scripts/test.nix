{ pkgs }:

pkgs.writeShellScriptBin "test-nix" ''
  echo "test-nix" | ${pkgs.cowsay}/bin/cowsay | ${pkgs.lolcat}/bin/lolcat
''

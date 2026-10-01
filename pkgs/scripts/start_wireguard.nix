{ pkgs, ... }:

pkgs.writeShellScriptBin "start_wireguard" ''
  sudo systemctl start wg-quick-wg0.service
''

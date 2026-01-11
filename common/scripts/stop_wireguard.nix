{ pkgs, ... }:

pkgs.writeShellScriptBin "stop_wireguard" ''
  sudo systemctl stop wg-quick-wg0.service
''

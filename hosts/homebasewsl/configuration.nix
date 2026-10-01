# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  user = "nixos";
in
{
  imports = [
  ];

  host.homeManagerHostname = "homebasewsl";
  home-manager.users.${config.host.username}.imports = [ ./home.nix ];
  host.username = user;
  host.isWsl = true;
  host.setNameservers = false;

  wsl.enable = true;
  wsl.defaultUser = user;

  wsl.wslConf.network.hostname = "nixos";

  # Release of the first install; do not change it.
  system.stateVersion = "24.11";
}

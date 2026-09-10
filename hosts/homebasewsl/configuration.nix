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
    inputs.home-manager.nixosModules.default
    ../../common/home-manager-config.nix
  ];

  host.homeManagerHostname = "homebasewsl";
  host.username = user;
  host.isWsl = true;
  host.setNameservers = false;

  wsl.enable = true;
  wsl.defaultUser = user;

  wsl.wslConf.network.hostname = "nixos";

  # Release of the first install; do not change it.
  system.stateVersion = "24.11";
}

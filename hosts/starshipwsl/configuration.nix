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
  user = "salhashemi2";
in
{
  imports = [
    inputs.home-manager.nixosModules.default
    ../../common/home-manager-config.nix
  ];

  host.homeManagerHostname = "starshipwsl";
  host.isWsl = true;
  host.setNameservers = false;

  wsl.enable = true;
  wsl.defaultUser = "salhashemi2";

  wsl.wslConf.network.hostname = "starship_wsl";

  # makes wsl not generate the `/etc/hosts` file...
  wsl.wslConf.network.generateHosts = false;
  # ...so we can write to it.

  # Release of the first install; do not change it.
  system.stateVersion = "24.11";
}

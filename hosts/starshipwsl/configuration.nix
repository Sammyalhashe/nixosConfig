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
  networking.extraHosts = ''
    11.125.37.101 mothership
    11.125.37.175 oldboy
    11.125.37.99  raspberrypi
    11.125.37.98  filestore
    11.125.37.135 homebase
  '';

  # Release of the first install; do not change it.
  system.stateVersion = "24.11";
}

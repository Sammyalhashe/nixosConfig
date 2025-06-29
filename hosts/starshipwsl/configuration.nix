# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, inputs, ... }:
let
hostname = "starshipwsl";
user = "salhashemi2";
homeDir = "/home";
in
{
  imports = [
    inputs.home-manager.nixosModules.default
    (
      import ../../common/home-manager.nix (
          { inherit inputs user homeDir hostname; }
      )
    )
  ];

  # enable flakes
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
  };

  # enable garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  wsl.enable = true;
  wsl.defaultUser = "salhashemi2";

  wsl.wslConf.network.hostname = "starship_wsl";


  # makes wsl not generate the `/etc/hosts` file...
  wsl.wslConf.network.generateHosts = false;
  # ...so we can write to it.
  networking.extraHosts = ''
    11.125.37.235 picloud.local
    11.125.37.99  raspberrypi.local
  '';


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}

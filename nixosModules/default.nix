{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./options.nix
    ./desktop.nix
    ./hyprland.nix
    ./shell.nix
    ./kdestuff.nix
    ./greetd.nix
    ./networking.nix
    ./sops.nix
    ./cachix.nix
  ];
}

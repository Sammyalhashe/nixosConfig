{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./hyprlock.nix
  ];

  programs.hyprland = {
    enable = lib.mkDefault config.host.enableHyprland;

    xwayland.enable = true;

    withUWSM = true;
  };
}

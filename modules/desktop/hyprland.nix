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
    enable = lib.mkDefault (config.host.enableHyprland && !config.host.isHeadless);

    xwayland.enable = true;

    withUWSM = false;
  };
}

{ config, lib, ... }:
{
  # disable things that are enabled by default
  stylix.targets.alacritty.enable = true;
  stylix.targets.tofi.enable = false;

  # enable the ones I want
  stylix.targets.zellij.enable = true;

  wayland.windowManager.hyprland.settings.bind = lib.mkIf config.wayland.windowManager.hyprland.enable [
    "SUPER SHIFT, T, exec, switch-theme"
  ];
}

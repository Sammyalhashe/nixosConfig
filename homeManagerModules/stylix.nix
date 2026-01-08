{ config, lib, inputs, osConfig ? null, ... }:
let
  # Enable Stylix if omarchy is enabled in the system config.
  # If osConfig is null (standalone HM), default to false (can be overridden).
  shouldEnable = if osConfig != null then osConfig.host.useOmarchy else false;
in
{
  # Disable stylix by default in Home Manager unless enabled by NixOS module or explicit config
  # Priority 900 is stronger than mkDefault (1000) but weaker than standard definitions (100).
  # This allows:
  # 1. 'homebase' (standard): default false (900) wins over module default (1000/1500). -> Disabled.
  # 2. 'oldboy' (omarchy): default true (900) wins over module default. -> Enabled.
  # 3. 'starshipwsl' (Stylix NixOS): propagation sets true (100) wins over 900. -> Enabled.
  # 4. 'work' (standalone): explicit true (100) wins over 900. -> Enabled.
  stylix.enable = lib.mkOverride 900 shouldEnable;

  # disable things that are enabled by default
  stylix.targets.alacritty.enable = true;
  stylix.targets.tofi.enable = false;

  # enable the ones I want
  stylix.targets.zellij.enable = true;

  wayland.windowManager.hyprland.settings.bind = lib.mkIf config.wayland.windowManager.hyprland.enable [
    "SUPER SHIFT, T, exec, switch-theme"
  ];
}

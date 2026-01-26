{
  config,
  lib,
  pkgs,
  inputs,
  osConfig ? null,
  ...
}:
let
  # Enable Stylix if omarchy is enabled in the system config.
  # If osConfig is null (standalone HM), default to false (can be overridden).
  shouldEnable = if osConfig != null then osConfig.host.useOmarchy else false;
  theme = import ../common/stylix-values.nix { inherit pkgs; };
in
{
  config = lib.mkMerge [
    {
      # Disable stylix by default in Home Manager unless enabled by NixOS module or explicit config
      # Priority 900 is stronger than mkDefault (1000) but weaker than standard definitions (100).
      stylix.enable = lib.mkOverride 900 shouldEnable;

      # disable things that are enabled by default
      stylix.targets.alacritty.enable = true;
      stylix.targets.tofi.enable = false;
      stylix.targets.wofi.enable = lib.mkForce false;
      stylix.targets.gnome.enable = false;

      # enable the ones I want
      stylix.targets.zellij.enable = true;

      wayland.windowManager.hyprland.settings.bind =
        lib.mkIf config.wayland.windowManager.hyprland.enable
          [
            "SUPER SHIFT, T, exec, switch-theme"
          ];
    }
    # Provide fallback configuration if Stylix is enabled but not configured.
    # Use priority 1100 (weaker than mkDefault) so other modules (like omarchy-nix or Stylix NixOS propagation) take precedence.
    (lib.mkIf config.stylix.enable {
      stylix.base16Scheme = lib.mkOverride 1100 theme.base16Scheme;
      stylix.image = lib.mkOverride 1100 theme.image;
      stylix.polarity = lib.mkOverride 1100 theme.polarity;
      stylix.fonts = lib.mkOverride 1100 theme.fonts;
      stylix.cursor = lib.mkOverride 1100 theme.cursor;
    })
  ];
}

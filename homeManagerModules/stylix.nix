{
  config,
  lib,
  pkgs,
  inputs,
  osConfig ? null,
  ...
}:
let
  # Enable Stylix if omarchy or my custom stylix option is enabled in the system config.
  # If osConfig is null (standalone HM), default to false (can be overridden).
  systemStylixEnabled =
    if osConfig != null then (osConfig.programs.stylix.enable or false) else false;
  omarchyEnabled = if osConfig != null then osConfig.host.useOmarchy else false;
  shouldEnable = systemStylixEnabled || omarchyEnabled;
  theme = import ../common/stylix-values.nix { inherit pkgs; };
in
{
  config = lib.mkMerge [
    {
      # Enable stylix by default in Home Manager if enabled by NixOS module.
      # Use mkDefault (1000) so it's easily overridden.
      stylix.enable = lib.mkDefault shouldEnable;

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

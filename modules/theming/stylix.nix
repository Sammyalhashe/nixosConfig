{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
with lib;
let
  cfg = config.programs.stylix;
  theme = import ./stylix-values.nix { inherit pkgs inputs; };
in
{
  options = {
    programs.stylix.enable = mkEnableOption "Whether to enable stylix";
  };
  config = mkIf cfg.enable {
    stylix.enable = true;

    # disable system targets
    stylix.targets.plymouth.enable = false;

    # Provide fallback configuration using weak priority (1100).
    stylix.base16Scheme = mkOverride 1100 theme.base16Scheme;
    stylix.image = mkOverride 1100 theme.image;
    stylix.polarity = mkOverride 1100 theme.polarity;
    stylix.fonts = mkOverride 1100 theme.fonts;
    stylix.cursor = mkOverride 1100 theme.cursor;

    environment.etc."current-theme".text = "light";
  };
}

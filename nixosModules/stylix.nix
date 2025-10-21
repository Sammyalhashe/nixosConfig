{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.stylix;
in
{
  options = {
    programs.stylix.enable = mkEnableOption "Whether to enable stylix";
  };
  config = mkIf cfg.enable {
    stylix.enable = true;
    stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
    # stylix.image = fetchurl {
    #   url = "https://c4.wallpaperflare.com/wallpaper/848/33/120/trees-path-dirt-road-fall-wallpaper-preview.jpg";
    #   hash = "sha256-xiPEpWNfNbBuX2REvEiw2LsRCFMfjU5vbfnbUQR/mTU=";
    # };
    stylix.polarity = "dark";
  };
}

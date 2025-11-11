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
    # stylix.image = pkgs.fetchurl {
    #   url = "https://unsplash.com/photos/75xPHEQBmvA/download?ixid=M3wxMjA3fDB8MXxhbGx8fHx8fHx8fHwxNzYyNzAzMDM0fA&force=true&w=1920";
    #   hash = "sha256-vWXPegjitJSEq5lFoSg6X6dRzqAQ8sGPMXNxuPNmXHA=";
    # };
    stylix.polarity = "dark";

    stylix.fonts = {
      serif = {
        package = "${pkgs.nerd-fonts.victor-mono}";
        name = "VictorMono Nerd Font Mono";
      };

      sansSerif = {
        package = "${pkgs.nerd-fonts.victor-mono}";
        name = "VictorMono Nerd Font Mono";
      };

      monospace = {
        package = "${pkgs.nerd-fonts.victor-mono}";
        name = "VictorMono Nerd Font Mono";
      };
    };
  };
}

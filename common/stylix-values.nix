{ pkgs }:
{
  base16Scheme = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
  polarity = "dark";
  fonts = {
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
}

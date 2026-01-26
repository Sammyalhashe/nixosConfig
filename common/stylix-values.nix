{ pkgs }:
{
  base16Scheme = {
    yaml = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/EdenEast/nightfox.nvim/refs/heads/main/extra/carbonfox/base16.yaml";
      sha256 = "sha256-GWk0t8V93+lCcxilH9wX3EaE5zozZgWE/Zr6FIb9cXs=";
    };
    use-ifd = "always";
  };
  # base16Scheme = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
  image = ./assets/BLACK_VII_desktop.jpg;
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

  cursor = {
    package = pkgs.catppuccin-cursors.mochaDark;
    name = "catppuccin-mocha-dark-cursors";
    size = 64;
  };
}

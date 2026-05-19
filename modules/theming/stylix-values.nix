{ pkgs }:
let
  mapleMonoName = if pkgs.stdenv.isDarwin then "Maple Mono NF" else "MapleMono NF";
in
{
  base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine-moon.yaml";
  image = ./assets/BLACK_VII_desktop.jpg;
  polarity = "dark";
  fonts = {
    serif = {
      package = "${pkgs.maple-mono.NF}";
      name = mapleMonoName;
    };

    sansSerif = {
      package = "${pkgs.maple-mono.NF}";
      name = mapleMonoName;
    };

    monospace = {
      package = "${pkgs.maple-mono.NF}";
      name = mapleMonoName;
    };

    sizes = {
      applications = 10;
      terminal = 14;
      desktop = 10;
      popups = 10;
    };
  };
  cursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };
}

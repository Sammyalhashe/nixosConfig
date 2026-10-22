{ pkgs, inputs }:
let
  mapleMonoName = if pkgs.stdenv.hostPlatform.isDarwin then "Maple Mono NF" else "MapleMono NF";
  bloombergVariant = "light";
in
{
  base16Scheme = inputs.bloomberg-theme.schemes.${bloombergVariant};
  image = ./assets/BLACK_VII_desktop.jpg;
  polarity = inputs.bloomberg-theme.palettes.${bloombergVariant}.polarity;
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

{ pkgs }:
{
  base16Scheme = {
    yaml = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/EdenEast/nightfox.nvim/refs/heads/main/extra/carbonfox/base16.yaml";
      sha256 = "sha256-GWk0t8V93+lCcxilH9wX3EaE5zozZgWE/Zr6FIb9cXs=";
    };
    use-ifd = "always";
  };
  image = ./assets/BLACK_VII_desktop.jpg;
  polarity = "dark";
  fonts = {
    serif = {
      package = "${pkgs.maple-mono.NF}";
      name = "MapleMono NF";
    };

    sansSerif = {
      package = "${pkgs.maple-mono.NF}";
      name = "MapleMono NF";
    };

    monospace = {
      package = "${pkgs.maple-mono.NF}";
      name = "MapleMono NF";
    };
  };
  cursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };
}

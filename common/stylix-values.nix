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
    # 1. UI/System Font (Menus, Taskbar, Windows)
    sansSerif = {
      package = pkgs.inter;
      name = "Inter";
    };

    # 2. Document Font (Serif)
    serif = {
      package = pkgs.noto-fonts;
      name = "Noto Serif";
    };

    # 3. Terminal/Code Font
    monospace = {
      package = pkgs.jetbrains-mono;
      name = "JetBrains Mono";
    };

    # 4. Global Font Size
    sizes = {
      applications = 10;
      terminal = 11;
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

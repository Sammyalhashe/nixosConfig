{ config, lib, pkgs, ... }:
{
  imports = [
    ../../homeManagerModules/desktop-base.nix
    ../../homeManagerModules
  ];

  home.packages =
    with pkgs;
    [
        bambu-studio
    ];

  # The waybar unit starts in any Hyprland session, including Ryoku's, which
  # brings its own bar.
  programs.waybar.systemd.enable = lib.mkForce false;

  # Ryoku composes ~/.config/starship.toml from its prompt layouts and theme
  # and rewrites it at login; home-manager writing it too blocked activation.
  # starship and jj-starship stay installed; only the file is Ryoku's.
  xdg.configFile."starship.toml".enable = lib.mkForce false;

  # Match the XDG_DATA_HOME/XDG_CACHE_HOME set in configuration.nix.
  xdg.dataHome = "${config.home.homeDirectory}/var/lib";
  xdg.cacheHome = "${config.home.homeDirectory}/var/cache";
}

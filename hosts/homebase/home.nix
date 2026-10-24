{ config, lib, ... }:
{
  imports = [
    ../../homeManagerModules/desktop-base.nix
    ../../homeManagerModules
  ];

  # The waybar unit starts in any Hyprland session, including Ryoku's, which
  # brings its own bar.
  programs.waybar.systemd.enable = lib.mkForce false;

  # Match the XDG_DATA_HOME/XDG_CACHE_HOME set in configuration.nix.
  xdg.dataHome = "${config.home.homeDirectory}/var/lib";
  xdg.cacheHome = "${config.home.homeDirectory}/var/cache";
}

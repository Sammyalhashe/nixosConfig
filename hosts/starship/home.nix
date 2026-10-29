{
  config,
  lib,
  pkgs,
  user,
  ...
}:
{
  imports = [
    ../../homeManagerModules/desktop-base.nix
    ../../homeManagerModules
  ];

  # The waybar unit starts in any Hyprland session, including Ryoku's, which
  # brings its own bar. Mango launches its own waybar, so it's unaffected.
  programs.waybar.systemd.enable = lib.mkForce false;

  programs.coinbase-cli.enable = true;

  home.username = "${user}";

  # Match the XDG_DATA_HOME/XDG_CACHE_HOME set in configuration.nix.
  xdg.dataHome = "${config.home.homeDirectory}/var/lib";
  xdg.cacheHome = "${config.home.homeDirectory}/var/cache";

  home.stateVersion = "24.05"; # Please read the comment before changing.

  home.packages = with pkgs; [
    onlyoffice-desktopeditors
    bambu-studio
    cloudflare-warp
  ];
}

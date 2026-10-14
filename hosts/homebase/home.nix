{ config, ... }:
{
  imports = [
    ../../homeManagerModules/desktop-base.nix
    ../../homeManagerModules
  ];

  # Match the XDG_DATA_HOME/XDG_CACHE_HOME set in configuration.nix.
  xdg.dataHome = "${config.home.homeDirectory}/var/lib";
  xdg.cacheHome = "${config.home.homeDirectory}/var/cache";
}

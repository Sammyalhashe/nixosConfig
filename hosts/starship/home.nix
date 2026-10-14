{
  config,
  pkgs,
  user,
  ...
}:
{
  imports = [
    ../../homeManagerModules/desktop-base.nix
    ../../homeManagerModules
  ];

  programs.coinbase-cli.enable = true;

  home.username = "${user}";

  # Match the XDG_DATA_HOME/XDG_CACHE_HOME set in configuration.nix.
  xdg.dataHome = "${config.home.homeDirectory}/var/lib";
  xdg.cacheHome = "${config.home.homeDirectory}/var/cache";

  home.stateVersion = "24.05"; # Please read the comment before changing.

  home.packages = with pkgs; [
    onlyoffice-desktopeditors
    cloudflare-warp
  ];
}

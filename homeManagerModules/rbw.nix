{
  pkgs,
  lib,
  osConfig ? { },
  ...
}:
let
  host = osConfig.host or { };
  graphical = !(host.isHeadless or false) && !(host.isWsl or false);
in
{
  programs.rbw = {
    enable = true;
    settings = {
      email = "sammy@salh.xyz";
      base_url = "https://vault.salh.xyz";
      lock_timeout = 3600;
      sync_interval = 3600;
      pinentry = if graphical then pkgs.pinentry-qt else pkgs.pinentry-curses;
    };
  };
}

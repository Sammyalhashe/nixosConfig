{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf ((config.host.isWsl || !config.host.greetd) && !config.host.isHeadless) {
    programs.kdeconnect.enable = true;
  };
}

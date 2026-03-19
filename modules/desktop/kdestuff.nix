{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf ((config.host.isWsl || !config.host.enableGreetd) && !config.host.isHeadless) {
    programs.kdeconnect.enable = true;
  };
}

{ config, pkgs, lib, ... }:

{
  config = lib.mkIf (config.host.isWsl || !config.host.greetd) {
    programs.kdeconnect.enable = true;
  };
}

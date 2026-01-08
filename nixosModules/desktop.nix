{ config, pkgs, lib, ... }:

{
  config = lib.mkIf (!config.host.isWsl && !config.host.greetd) {
    # Enable KDE
    services.xserver.enable = true;
    services.displayManager.sddm.enable = true;
    services.desktopManager.plasma6.enable = true;
  };
}

{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkMerge [
    (lib.mkIf (!config.host.isWsl && !config.host.greetd) {
      # Enable KDE
      services.xserver.enable = true;
      services.displayManager.sddm.enable = true;
      services.desktopManager.plasma6.enable = true;
    })
    (lib.mkIf (!config.host.isWsl) {
      # Enable Steam
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
      };
    })
  ];
}
{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkMerge [
    (lib.mkIf (!config.host.isWsl && !config.host.isHeadless) {
      # Enable KDE only if NOT headless
      services.xserver.enable = true;
      # Conditionally enable SDDM based on greetd flag, but only if not headless
      services.displayManager.sddm.enable = !config.host.greetd;
      services.desktopManager.plasma6.enable = true;

      # Enable Steam
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
      };
    })
  ];
}

{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkMerge [
    {
      # Defaults for physical hosts
      host.enableKDE = lib.mkDefault (!config.host.isWsl && !config.host.isHeadless);
      host.enableMango = lib.mkDefault (!config.host.isWsl && !config.host.isHeadless);
      host.enableHyprland = lib.mkDefault (!config.host.isWsl && !config.host.isHeadless);
    }
    (lib.mkIf (config.host.enableKDE) {
      # Enable KDE if enable flag is true
      services.xserver.enable = true;
      # Conditionally enable SDDM based on greetd flag
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

{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hyprland.nix
    ./kdestuff.nix
    ./greetd.nix
  ];

  config = lib.mkMerge [
    {
      # Defaults for physical hosts
      host.enableKDE = lib.mkDefault (!config.host.isWsl && !config.host.isHeadless);
      host.enableMango = lib.mkDefault (!config.host.isWsl && !config.host.isHeadless);
      host.enableHyprland = lib.mkDefault (!config.host.isWsl && !config.host.isHeadless);

      # Modern D-Bus implementation
      services.dbus.implementation = "broker";
    }
    (lib.mkIf (!config.host.isWsl && !config.host.isHeadless) {
      # Audio (PipeWire)
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };
    })
    (lib.mkIf (config.host.enableKDE && !config.host.isHeadless) {
      # Enable KDE if enable flag is true
      services.xserver.enable = true;
      # Conditionally enable SDDM based on greetd flag
      services.displayManager.sddm.enable = !config.host.enableGreetd;
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

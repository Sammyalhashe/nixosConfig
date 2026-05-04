{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkMerge [
    (lib.mkIf (config.host.enableKDE && !config.host.isHeadless) {
      # Enable KDE if enable flag is true
      services.xserver.enable = true;
      # Conditionally enable SDDM based on greetd flag
      services.displayManager.sddm.enable = !config.host.enableGreetd;
      services.desktopManager.plasma6.enable = true;

      environment.systemPackages = with pkgs; [
        # KDE Utilities
        kdePackages.discover # Optional: Software center for Flatpaks/firmware updates
        kdePackages.kcalc # Calculator
        kdePackages.kcharselect # Character map
        kdePackages.kclock # Clock app
        kdePackages.kcolorchooser # Color picker
        kdePackages.kolourpaint # Simple paint program
        kdePackages.ksystemlog # System log viewer
        kdePackages.sddm-kcm # SDDM configuration module
        kdiff3 # File/directory comparison tool

        # Hardware/System Utilities (Optional)
        kdePackages.isoimagewriter # Write hybrid ISOs to USB
        kdePackages.partitionmanager # Disk and partition management
        hardinfo2 # System benchmarks and hardware info
        wayland-utils # Wayland diagnostic tools
        wl-clipboard # Wayland copy/paste support
        vlc # Media player
      ];

      # Enable Steam
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
      };
      programs.kdeconnect = {
        enable = true;
      };
      networking.firewall = {
        allowedTCPPortRanges = [
          {
            from = 1714;
            to = 1764;
          }
        ];
        allowedUDPPortRanges = [
          {
            from = 1714;
            to = 1764;
          }
        ];
      };
    })
  ];

}

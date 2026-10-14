{ lib, inputs, ... }:
let
  my_imports = [
    ./crush.nix
    ./ghostty.nix
    ./home-common.nix
    ./mangowc.nix
    ./mods.nix
    ./opencode.nix
    ./plasma.nix
    ./startup-fix.nix
    ./stylix.nix
    ./waybar.nix
    ./wofi.nix
    (
      { config, osConfig, ... }:
      {
        programs.vicinae.enable = lib.mkDefault osConfig.host.enableVicinae;
        programs.quickNotes = {
          enable = osConfig.host.enableVicinae;
          notesDir = "${config.home.homeDirectory}/Nextcloud/Notes/Inbox";
        };
      }
    )
    {
      programs.coinbase-cli.enable = true;
      stylix.targets.gtk.enable = false;
      stylix.targets.kde.enable = false;
      stylix.targets.qt.enable = false;
      stylix.targets.wofi.enable = false;
      stylix.targets.mako.enable = true;
      stylix.targets.btop.enable = false;
    }
  ];
in
{
  imports = my_imports;
}

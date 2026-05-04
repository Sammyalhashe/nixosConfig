{ lib, inputs, ... }:
let
  my_imports = [
    ./home-common.nix
    ./wofi.nix
    ./stylix.nix
    ./gemini-cli.nix
    ./startup-fix.nix
    ./mods.nix
    ./mangowc.nix
    ./ghostty.nix
    ./waybar.nix
    ./crush.nix
    ./aider.nix
    ./opencode.nix
    ./plasma.nix
    {
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

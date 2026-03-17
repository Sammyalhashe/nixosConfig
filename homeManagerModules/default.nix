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
    {
      stylix.targets.gtk.enable = false;
      stylix.targets.kde.enable = false;
      stylix.targets.wofi.enable = false;
      stylix.targets.mako.enable = false;
      stylix.targets.btop.enable = false;
    }
  ];
in
{
  imports = my_imports;
}

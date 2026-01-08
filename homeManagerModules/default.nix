{ lib, inputs, ... }:
let
  my_imports = [
    ./home-common.nix
    # ./desktop.nix
    # ./neovim.nix
    ./wofi.nix
    ./stylix.nix
    ./gemini-cli.nix
    ./pomodoro.nix
    ./startup-fix.nix
    {
      # stylix.targets.gtk.enable = false;
      stylix.targets.wofi.enable = false;
      # stylix.targets.hyprland.enable = false;
      # stylix.targets.hyprlock.enable = false;
      stylix.targets.mako.enable = false;
      stylix.targets.btop.enable = false;
    }
  ];
in
{
  imports = my_imports;
}

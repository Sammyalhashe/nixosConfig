{ lib, inputs, ... }:
let
  my_imports = [
    ./home-common.nix
    ./neovim.nix
    ./stylix.nix
    ./aider.nix
  ];
in
{
  imports = my_imports;

  # Disable desktop-related stylix targets to avoid pulling in heavy dependencies like KDE/QT/GTK
  stylix.targets.gtk.enable = false;
  stylix.targets.kde.enable = false;
  stylix.targets.qt.enable = false;
  stylix.targets.gnome.enable = false;
  stylix.targets.xfce.enable = false;

  # Disable Wayland/Window Manager specific styling
  stylix.targets.hyprland.enable = false;
  stylix.targets.waybar.enable = false;
  stylix.targets.dunst.enable = false;
  stylix.targets.swaylock.enable = false;
  stylix.targets.hyprlock.enable = false;
}

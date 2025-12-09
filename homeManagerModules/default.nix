{ lib, inputs, ... }:
let
  my_imports = [
    ./alacritty.nix
    # ./desktop.nix
    ./direnv.nix
    # ./neovim.nix
    ./nixpkgs.nix
    ./starship.nix
    ./tmux.nix
    ./wezterm.nix
    ./wofi.nix
    ./yazi.nix
    ./zellij.nix
    ./zsh.nix
    ./nushell.nix
    ./stylix.nix
    ./crush.nix
    ./gemini-cli.nix
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

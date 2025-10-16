{ lib, inputs, ... }:
let
  my_imports = [
    ./alacritty.nix
    ./direnv.nix
    ./neovim.nix
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
  ];
in
{
  imports = my_imports;
}

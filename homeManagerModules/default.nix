{lib, inputs, ...}:
let my_imports = [
    ./alacritty.nix
    ./desktop.nix
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
];
in
{
    imports = my_imports;
}

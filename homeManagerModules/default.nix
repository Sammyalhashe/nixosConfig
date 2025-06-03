{lib, ...}:
let my_imports = [
    ./alacritty.nix
    ./direnv.nix
    ./neovim.nix
    ./nixpkgs.nix
    ./starship.nix
    ./tmux.nix
    ./wezterm.nix
    ./zsh.nix
];
in
{
    imports = my_imports;
}

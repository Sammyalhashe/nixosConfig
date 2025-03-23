{lib, ...}:
let my_imports = [
    ./nixpkgs.nix
    ./alacritty.nix
    ./zsh.nix
    ./starship.nix
    ./tmux.nix
    ./direnv.nix
    ./wezterm.nix
];
in
{
    imports = my_imports;
}

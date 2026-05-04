{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./zellij.nix
    ./nushell.nix
    ./tmux.nix
    ./yazi.nix
  ];

  home.packages = with pkgs; [
    btop
    podman
    ripgrep
    fzf
    jq
    python3
    rsync
  ];

  programs.starship.enable = true;

  # Disable Stylix targets that might pull in graphical dependencies on headless Pi

  home.stateVersion = "23.11";
}

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
    ./picoclaw.nix
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
  programs.git = {
    enable = true;
    settings = {
      user.name = "Sammy Al Hashemi";
      user.email = "sammy@salh.xyz";
    };
  };

  # Disable Stylix targets that might pull in graphical dependencies on headless Pi

  home.stateVersion = "23.11";
}

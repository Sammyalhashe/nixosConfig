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
  ];

  home.packages = with pkgs; [
    btop
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
  stylix.targets.nixvim.enable = false;

  home.stateVersion = "23.11";
}

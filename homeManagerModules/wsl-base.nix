{
  config,
  pkgs,
  inputs,
  user,
  homeDir,
  lib,
  ...
}:
let
  extended-nixvim = import ./lib/nixvim.nix { inherit pkgs inputs config; } { nixvim.wsl = true; };
in
{
  imports = [ ./base.nix ];

  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    # c compilers
    gcc

    # applications
    emacs
    extended-nixvim

    # terminal utilities
    blesh
    cargo
    cava
    spotify-player
    stow

    (import ../pkgs/scripts/start_wireguard.nix { inherit pkgs; })
    (import ../pkgs/scripts/stop_wireguard.nix { inherit pkgs; })
  ];

  home.file = {
    ".latexmkrc".text = ''
      $pdf_previewer = 'start mupdf';
      $new_viewer_always = 0;
      $pdf_update_method = 2;
      $pdf_update_signal = 'SIGHUP';
    '';
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.home-manager.enable = true;
}

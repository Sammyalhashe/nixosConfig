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
  nixvim-package = inputs.nixvim.packages.x86_64-linux.default;

  nixvim-wsl = nixvim-package.extend { nixvim.wsl = true; };
  extended-nixvim =
    if config.stylix.enable then
      nixvim-wsl.extend config.stylix.targets.nixvim.exportedModule
    else
      nixvim-wsl;
in
{
  imports = [ ./home-common.nix ];

  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    # c compilers
    gcc

    # applications
    brave
    emacs
    kitty
    mupdf
    extended-nixvim
    ghostty

    # terminal utilities
    blesh
    blueman
    cargo
    cava
    pavucontrol
    spotify-player
    stow
    wezterm

    (import ./scripts/start_wireguard.nix { inherit pkgs; })
    (import ./scripts/stop_wireguard.nix { inherit pkgs; })
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
    NIXOS_OZONE_WL = "1";
  };

  programs.home-manager.enable = true;
}

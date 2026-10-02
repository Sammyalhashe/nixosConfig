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
  extended-nixvim = import ../../homeManagerModules/lib/nixvim.nix {
    inherit pkgs inputs config;
  } { };
in
{
  imports = [
    ../../homeManagerModules/base.nix
    ../../homeManagerModules/claude-code.nix
    ./home-modules.nix
  ];

  home.username = "${user}";

  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    extended-nixvim
    jujutsu
    openssl
    wget
    gcc
    cargo
    cachix
    devenv

    # terminal utilities
    blesh
    spotify-player
    stow
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

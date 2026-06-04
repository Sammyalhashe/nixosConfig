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
  nixvim-package = inputs.nixvim.packages."${pkgs.stdenv.hostPlatform.system}".default;
  extended-nixvim =
    if config.stylix.enable && config.stylix.targets.nixvim.enable then
      nixvim-package.extend config.stylix.targets.nixvim.exportedModule
    else
      nixvim-package;
in
{
  imports = [
    ./home-common.nix
    ../homeManagerModules/claude-code.nix
    ../homeManagerModules/aider.nix
  ];

  programs.aider.enable = true;

  home.username = "${user}";

  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    extended-nixvim
    jujutsu
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

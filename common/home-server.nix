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
    if (config.stylix.enable or false) && (config.stylix.targets.nixvim.enable or false) then
      nixvim-package.extend config.stylix.targets.nixvim.exportedModule
    else
      nixvim-package;
in
{
  imports = [ ./home-common.nix ];

  home.username = user;
  home.homeDirectory = homeDir;

  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    extended-nixvim
    jujutsu
    gcc
    cargo
    cachix
    lazygit

    # system tools
    btop
    htop
    unzip
    zip
    jq
    yq-go
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.home-manager.enable = true;
}

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

  # nixvim-package = inputs.nixvim-config.packages.${system}.default;
  extended-nixvim =
    if config.stylix.enable && config.stylix.targets.nixvim.enable then
      nixvim-package.extend config.stylix.targets.nixvim.exportedModule
    else
      nixvim-package;
in
{
  imports = [
    ./home-common.nix
    ../homeManagerModules/openclaw.nix
    ../homeManagerModules/aider.nix
    ../homeManagerModules/opencode.nix
    ../homeManagerModules/coinbase-trader.nix
  ];

  home.username = "${user}";

  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    # minimal packages for a server
    direnv
    extended-nixvim
    fzf
    git
    neovim
    podman
    ripgrep
    tmux
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

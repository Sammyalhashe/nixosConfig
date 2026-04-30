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
in
{
  imports = [
    ./home-common.nix
    # ../homeManagerModules/openclaw.nix
    ../homeManagerModules/aider.nix
    ../homeManagerModules/claude-code.nix
    ../homeManagerModules/opencode.nix
    ../homeManagerModules/coinbase-trader.nix
    ../homeManagerModules/phar-liquidity-bot.nix
  ];

  home.username = "${user}";

  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    # minimal packages for a server
    direnv
    nixvim-package
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

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

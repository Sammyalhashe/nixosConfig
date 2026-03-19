{
  config,
  pkgs,
  inputs,
  user,
  homeDir,
  lib,
  ...
}:
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

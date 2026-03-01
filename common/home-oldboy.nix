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
    ../homeManagerModules/coinbase-trader.nix
  ];

  home.username = "${user}";

  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    # minimal packages for a server
    git
    tmux
    ripgrep
    fzf
    neovim
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

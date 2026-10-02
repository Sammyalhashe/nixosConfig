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
    # ../../homeManagerModules/openclaw.nix
    ../../homeManagerModules/claude-code.nix
    ../../homeManagerModules/opencode.nix
    ../../homeManagerModules/coinbase-trader.nix
    ../../homeManagerModules/phar-liquidity-bot.nix
    ../../homeManagerModules/coinbase-cli.nix
  ];

  home.username = "${user}";

  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    # minimal packages for a server
    direnv
    extended-nixvim
    fzf
    git
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

  programs.coinbase-cli.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

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
  llm-packages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
    cline
  ];
in
{
  imports = [
    ../../homeManagerModules/base.nix
    ../../homeManagerModules/claude-code.nix
    ../../homeManagerModules/codex.nix
    ../../homeManagerModules/goose.nix
    ./home-modules.nix
    inputs.rex.homeManagerModules.default
  ];

  # Personal Rex server on $XDG_RUNTIME_DIR/rex/server.sock. Macs reach it over an
  # SSH-forwarded socket, so it needs no network listener.
  services.rex.enable = true;
  # The guard lives in ~/.ssh/config, which home-manager doesn't manage here.
  programs.rex.sshGuard = false;

  home.username = "${user}";

  home.stateVersion = "24.05";

  home.packages =
    with pkgs;
    [
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
    ]
    ++ llm-packages;

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

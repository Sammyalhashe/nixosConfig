{
  config,
  pkgs,
  inputs,
  user,
  homeDir,
  ...
}:
let
  # inherit (pkgs.stdenv.hostPlatform) system;
  nixvim-package = inputs.nixvim.packages.x86_64-linux.default;

  nixvim-wsl = nixvim-package.extend { nixvim.wsl = false; };
  # nixvim-package = inputs.nixvim-config.packages.${system}.default;
  extended-nixvim = if config.stylix.enable
    then nixvim-wsl.extend config.stylix.targets.nixvim.exportedModule
    else nixvim-wsl;
in
{
  imports = [ ./home-common.nix ];

  home.username = "${user}";
  # TODO: Gotta transfer this file to it's own copy for each system.
  home.homeDirectory = "${homeDir}";

  home.stateVersion = "24.05"; # Please read the comment before changing.

  home.packages = with pkgs; [
    lazygit

    # neovim
    extended-nixvim

    # terminal utilities
    cargo

    (import ./scripts/start_wireguard.nix { inherit pkgs; })
    (import ./scripts/stop_wireguard.nix { inherit pkgs; })
  ];

  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # TODO: Figure this out somehow
    # ".clang-format".source = .dotfiles/language_configs/cpp/.clang-format;
    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # syncthing
  # services.syncthing.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

}

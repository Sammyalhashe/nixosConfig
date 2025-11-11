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
  extended-nixvim = nixvim-wsl.extend config.stylix.targets.nixvim.exportedModule;
in
let
  my_packages = with pkgs; [
    git
    lazygit

    # applications
    emacs
    mupdf
    # neovim
    extended-nixvim

    # terminal utilities
    bat
    blesh
    cargo
    cava
    cowsay
    delta
    dua
    fd
    fortune
    fzf
    gh
    neofetch
    ripgrep
    starship
    tmux
    yazi
    zellij
  ];
in
let
  res = my_packages ++ [
    (import ./scripts/test.nix { inherit pkgs; })
    (import ./scripts/hgrep.nix { inherit pkgs; })
    (import ./scripts/crypto.nix { inherit pkgs; })
    (import ./scripts/tmux-cht.nix { inherit pkgs; })
    (import ./scripts/fzf-man.nix { inherit pkgs; })
    (import ./scripts/start_wireguard.nix { inherit pkgs; })
    (import ./scripts/stop_wireguard.nix { inherit pkgs; })
  ];
in
{
  # imports = inputs.self.outputs.homeManagerModules.default;
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "${user}";
  # TODO: Gotta transfer this file to it's own copy for each system.
  home.homeDirectory = "${homeDir}/${user}";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = res;

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # TODO: Figure this out somehow
    # ".clang-format".source = .dotfiles/language_configs/cpp/.clang-format;
    ".latexmkrc".text = ''
      $pdf_previewer = 'start mupdf';
      $new_viewer_always = 0;
      $pdf_update_method = 2;
      $pdf_update_signal = 'SIGHUP'; 
    '';
    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at eithErer
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/salhashemi2/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
    NIXOS_OZONE_WL = "1";
  };

  # syncthing
  # services.syncthing.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

}

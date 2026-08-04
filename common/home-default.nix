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
  # inherit (pkgs.stdenv.hostPlatform) system;
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
    ./home-entertainment.nix
    ../homeManagerModules/aider.nix
    ../homeManagerModules/zeal.nix
  ];

  programs.aider.enable = true;

  home.username = "${user}";

  home.stateVersion = "24.05"; # Please read the comment before changing.

  home.packages = with pkgs; [
    jujutsu
    inputs.fromscratch.packages."${pkgs.stdenv.hostPlatform.system}".default
    inputs.homebase-manager.packages."${pkgs.stdenv.hostPlatform.system}".default

    # c compilers
    gcc

    # desktop
    wofi
    rofi
    tofi

    # applications
    beeper
    brave
    cachix
    deskflow
    devenv
    emacs
    extended-nixvim
    hyprlock
    hyprpaper
    kdePackages.partitionmanager
    kitty
    mupdf
    nextcloud-client
    proton-vpn
    telegram-desktop
    thunar
    thunderbird
    wireguard-ui
    zoom-us

    # unfree applications
    obsidian
    discord

    # AI
    python313Packages.huggingface-hub

    # terminal utilities
    blesh
    blueman
    cargo
    cava
    ghostty
    pavucontrol
    spotify-player
    stow
    waypipe

    # GUI utilities (moved from home-common.nix)
    grim
    notejot
    slurp
    wl-clipboard
    xclip

    # jupyter
    python3
    python3Packages.jupyter
    python3Packages.ipykernel

    # fonts

    # wayland stuff
    xwayland

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
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

  home.sessionVariables = {
    EDITOR = "nvim";
    NIXOS_OZONE_WL = "1";
  };

  # syncthing
  services.syncthing.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.mangowc.enable = true;

  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [
      pkgs.kdePackages.plasma-browser-integration
    ];
    configPath = "${config.xdg.configHome}/mozilla/firefox";
    profiles.default = {
      name = "default";
      isDefault = true;
      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        bitwarden
        sponsorblock
        darkreader
      ];
    };
  };

  stylix.targets.firefox.profileNames = [ "default" ];

  programs.zeal = {
    enable = true;
    docsets = {
      Python_3 = {
        url = "https://sanfrancisco.kapeli.com/feeds/Python_3.tgz";
        hash = "sha256-SGP9kY9j5K9aMVtd+sVrLixtvYftU9iRRFfqGwBRdGY=";
      };
      JavaScript = {
        url = "https://sanfrancisco.kapeli.com/feeds/JavaScript.tgz";
        hash = "sha256-SGP9kY9j5K9aMVtd+sVrLixtvYftU9iRRFfqGwBRdGY=";
      };
      Cpp = {
        url = "https://sanfrancisco.kapeli.com/feeds/C++.tgz](https://sanfrancisco.kapeli.com/feeds/C++.tgz";
        hash = "sha256-SGP9kY9j5K9aMVtd+sVrLixtvYftU9iRRFfqGwBRdGY=";
      };
    };
  };
}

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

  # nixvim-package = inputs.nixvim-config.packages.${system}.default;
  extended-nixvim = nixvim-package.extend config.stylix.targets.nixvim.exportedModule;
in
{
  imports = [ ./home-common.nix ];

  home.username = "${user}";

  home.stateVersion = "24.05"; # Please read the comment before changing.

  home.packages = with pkgs; [
    inputs.zen-browser.packages."${pkgs.system}".default
    jujutsu

    # c compilers
    gcc

    # desktop
    wofi
    rofi
    tofi

    # applications
    anytype
    brave
    emacs
    firefox
    hyprlock
    hyprpaper
    extended-nixvim
    kdePackages.partitionmanager
    kitty
    mupdf
    nextcloud-client
    protonvpn-gui
    thunderbird
    wireguard-ui
    xfce.thunar

    # unfree applications
    obsidian
    discord

    # terminal utilities
    blesh
    blueman
    cargo
    cava
    ghostty
    pavucontrol
    spotify-player
    stow
    wezterm
    waypipe

    # jupyter
    python3
    python3Packages.jupyter
    python3Packages.ipykernel

    # https://discourse.nixos.org/t/how-to-support-clipboard-for-neovim/9534/3
    wl-clipboard

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
}

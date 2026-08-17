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

  # Deskflow (KVM software sharing this machine's keyboard/mouse) as the
  # server. homebase boots KDE Plasma (services.displayManager.defaultSession
  # = "plasma"), which natively honors XDG autostart entries. (An earlier
  # Hyprland exec-once approach was inert here -- Hyprland is disabled and the
  # session is Plasma.)
  xdg.configFile."autostart/deskflow.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Deskflow
    Comment=Share this machine's keyboard and mouse (server)
    Exec=${pkgs.deskflow}/bin/deskflow
    Terminal=false
    X-KDE-autostart-phase=2
  '';

  # Seed the server config only if missing, since Deskflow rewrites this
  # file with its own settings once it has run (don't clobber user-adjusted
  # state on every activation). KQ7DV474L1 is the Bloomberg corporate Mac
  # connecting in as a client (see bbNixosConfig's home-KQ7DV474L1.nix).
  home.activation.seedDeskflowConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        CONF_DIR="${homeDir}/.config/Deskflow"
        CONF="$CONF_DIR/Deskflow.conf"
        SERVER_CONF="$CONF_DIR/server.conf"
        if [ ! -f "$CONF" ]; then
          mkdir -p "$CONF_DIR"
          cat > "$SERVER_CONF" <<'EOF'
    section: screens
    	homebase:
    	KQ7DV474L1:
    end

    section: links
    	homebase:
    		right = KQ7DV474L1
    	KQ7DV474L1:
    		left = homebase
    end
    EOF
          cat > "$CONF" <<EOF
    [core]
    coreMode=2
    computerName=homebase

    [gui]
    startCoreWithGui=true

    [server]
    externalConfig=true
    externalConfigFile=$SERVER_CONF
    EOF
        fi
  '';
}

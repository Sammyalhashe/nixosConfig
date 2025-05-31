{ config, pkgs, inputs, user, homeDir, ... }:
let darwin = pkgs.system == "x86_64-darwin";
in
let my_packages = with pkgs; if darwin then [
      # # Adds the 'hello' command to your environment. It prints a friendly
      # # "Hello, world!" when run.

      # c compilers
      gcc

      # desktop
      # wofi
      # tofi

      # applications
      neovim
      # kitty
      # waybar
      # brave
      # firefox
      # zathura
      # hyprpaper
      # hyprlock
      # kdeconnect
      # thunderbird
      # maestral-gui
      syncthing

      # unfree applications
      # obsidian
      # jetbrains-toolbox

      # terminal utilities
      alacritty
      cowsay
      fortune
      fzf
      gh
      neofetch
      neofetch
      ripgrep
      direnv
      spotify-player
      starship
      tmux
      yazi


      # https://discourse.nixos.org/t/how-to-support-clipboard-for-neovim/9534/3
      # wl-clipboard

      # fonts
      iosevka


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


]
else [
      inputs.zen-browser.packages."${pkgs.system}".default
      git

      # c compilers
      gcc

      # desktop
      wofi
      # tofi

      # applications
      brave
      emacs
      firefox
      hyprlock
      hyprpaper
      kitty
      mupdf
      neovim
      nextcloud-client
      plasma5Packages.kdeconnect-kde
      protonvpn-gui
      syncthing
      thunderbird

      # unfree applications
      obsidian
      discord

      # terminal utilities
      alacritty
      bat
      blesh
      blueman
      cava
      cowsay
      delta
      dua
      fd
      fortune
      fzf
      gh
      ghostty
      neofetch
      neofetch
      pavucontrol
      ripgrep
      spotify-player
      starship
      stow
      tmux
      wezterm
      yazi
      zellij


      # https://discourse.nixos.org/t/how-to-support-clipboard-for-neovim/9534/3
      wl-clipboard

      # fonts
      iosevka

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
];
in
let res = my_packages ++ [
      (import ./scripts/test.nix { inherit pkgs; })
      (import ./scripts/hgrep.nix { inherit pkgs; })
      (import ./scripts/crypto.nix { inherit pkgs; })
      (import ./scripts/tmux-cht.nix { inherit pkgs; })
      (import ./scripts/fzf-man.nix { inherit pkgs; })
];
in
{
    # imports = inputs.self.outputs.homeManagerModules.default;
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    home.username = "${user}";
    # TODO Gotta transfer this file to it's own copy for each system.
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
    services.syncthing.enable = true;

    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;

}

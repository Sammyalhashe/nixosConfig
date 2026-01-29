{ pkgs, inputs, ... }:
{
  home.packages =
    with pkgs;
    [
      # common applications
      git
      nodejs

      # nur repos
      pkgs.nur.repos.charmbracelet.glow
      pkgs.nur.repos.charmbracelet.mods
      pkgs.nur.repos.charmbracelet.skate
      pkgs.nur.repos.charmbracelet.crush
      pkgs.nur.repos.charmbracelet.pop
      pkgs.nur.repos.charmbracelet.gum

      # terminal utilities
      alacritty
      bat
      cowsay
      delta
      dua
      fd
      fortune
      fzf
      gemini-cli
      gh
      grim
      neofetch
      notejot
      pandoc
      ripgrep
      russ
      slurp
      sops
      starship
      texliveSmall
      tmux
      wl-clipboard
      xclip
      yazi
      zellij
      zoxide

      # fonts
      iosevka
    ]
    ++ [
      (import ./scripts/test.nix { inherit pkgs; })
      (import ./scripts/hgrep.nix { inherit pkgs; })
      (import ./scripts/crypto.nix { inherit pkgs; })
      (import ./scripts/tmux-cht.nix { inherit pkgs; })
      (import ./scripts/fzf-man.nix { inherit pkgs; })
      (import ./scripts/system-copy.nix { inherit pkgs; })
    ];

  systemd.user.services.neovim_server = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "Neovim server to connect to for fast startup";
    };
    Service = {
      ExecStart = "${pkgs.bash}/bin/bash -c 'exec $(which nvim) --listen 127.0.0.1:8888 --headless'";
      Restart = "always";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}

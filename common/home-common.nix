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
      wl-clipboard
      xclip
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
      neofetch
      pandoc
      ripgrep
      russ
      sops
      starship
      texliveSmall
      tmux
      yazi
      zellij

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
}

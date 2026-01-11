{ pkgs, inputs, ... }:
{
  home.packages =
    with pkgs;
    [
      # common applications
      git

      # nur repos
      nur.repos.charmbracelet.glow
      nur.repos.charmbracelet.mods
      nur.repos.charmbracelet.skate
      nur.repos.charmbracelet.crush

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
      neofetch
      ripgrep
      starship
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
    ];
}

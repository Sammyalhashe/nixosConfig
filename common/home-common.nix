{ pkgs, inputs, ... }:
{
  home.packages =
    with pkgs;
    [
      # common applications
      git
      nodejs

      # nur repos

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

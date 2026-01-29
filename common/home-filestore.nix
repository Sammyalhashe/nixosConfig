{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git
    ripgrep
    fd
    fzf
    bat
    gemini-cli

    # minimal charmbracelet
    nur.repos.charmbracelet.gum
    nur.repos.charmbracelet.glow
    nur.repos.charmbracelet.mods

    # system tools
    btop
    htop
    unzip
    zip
    jq
    yq-go

    # networking
    dig
    bind
  ];
}

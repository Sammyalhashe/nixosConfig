{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    spotify
    vlc
  ];
}
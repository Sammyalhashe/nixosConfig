{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    spotify
    vlc
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    steam
  ];
}

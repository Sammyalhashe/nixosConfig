{ config, pkgs, stdenv, ... }:
let
    font = "";
in
{
    programs.wezterm = {
        enable = true;
        extraConfig = builtins.readFile ./wezterm.lua;
    };
}

{ config, pkgs, stdenv, ... }:
let
    font = "";
in
{
    programs.wezterm = {
        enable = true;

        extraConfig = {
            "wezterm/wezterm.lua".source = builtins.readFile ./wezterm.lua;
        };
    };
}

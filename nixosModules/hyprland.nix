{ config, pkgs, lib, inputs, ... }:
{
    imports = [
        ./hyprlock.nix
    ];
    
    programs.hyprland = {
        enable = true;

        xwayland.enable = true;

        withUWSM = true;
    }; 
}

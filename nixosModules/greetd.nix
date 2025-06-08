
{ pkgs, lib, inputs, username, ... }:
{
    services.greetd = {
        enable = true;

        vt = 3;
        
        settings = {
           user = username; 
           command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        };
    }; 
}

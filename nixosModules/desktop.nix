{ config, pkgs, lib, inputs, ... }:

{
    # hyprland configuration
    # uncomment the following lines for hyprland
    # programs.hyprland.enable = true;
    # environment.sessionVariables.NIXOS_OZONE_WL = "1";
    # imports = [
        # ./hyprland.nix
    # ];

    # https://discourse.nixos.org/t/how-to-enable-login-screen-and-start-hyperland-after-login/37775
    # services.xserver.enable = true;
    # services.displayManager.sddm.settings = {
    #       enable = true;
    #       theme = "sddm-sugar-dark";
    #       wayland = {
    #           enable = true;
    #       };
    # };

    # KDE configuration
    # uncomment the following lines for KDE

    # Enable KDE
    services.xserver.enable = true;
    services.displayManager.sddm.enable = true;
    services.desktopManager.plasma6.enable = true;
}



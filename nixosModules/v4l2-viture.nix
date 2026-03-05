{ config, pkgs, inputs, lib, ... }:

let
  user = "salhashemi2";
in
{
  # This module preserves the work done for mgschwan/viture_virtual_display
  # To enable, import this in your host configuration.
  
  # environment.systemPackages = [
  #   inputs.viture-virtual-display.packages.${pkgs.system}.default
  # ];

  # users.users.${user}.extraGroups = [ "video" "input" ];

  # services.udev.extraRules = ''
  #   SUBSYSTEMS=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="35ca", ATTRS{idProduct}=="1121", MODE="0666", GROUP="users"
  #   SUBSYSTEMS=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="35ca", ATTRS{idProduct}=="101d", MODE="0666", GROUP="users"
  # '';

  # Note: The mangowc changes (mousebinds, tagmon, virtual outputs) 
  # are currently in homeManagerModules/mangowc.nix and were not moved here
  # as they are generally useful for window management.
}

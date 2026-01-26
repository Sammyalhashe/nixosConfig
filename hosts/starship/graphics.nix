{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Fix for Intel Graphics (Lunar Lake)
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # THIS IS THE FIX
    extraPackages = with pkgs; [
      vpl-gpu-rt # Important for Lunar Lake (Intel VPL)
      intel-media-driver # For VA-API video acceleration
    ];
  };
  # services.xserver.videoDrivers = [ "modesetting" ];
  # Lunar Lake performs much better with the 'xe' driver over 'modesetting'
  boot.initrd.kernelModules = [ "xe" ];
  services.xserver.videoDrivers = [ "xe" ];
}

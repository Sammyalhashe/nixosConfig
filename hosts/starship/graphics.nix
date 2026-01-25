{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Fix for Intel Graphics (Lunar Lake)
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "modesetting" ];
}

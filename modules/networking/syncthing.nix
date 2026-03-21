{ config, lib, ... }:
{
  services.syncthing = {
    enable = lib.mkDefault false;
  };
}

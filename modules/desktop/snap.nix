{ config, lib, ... }:
{
  services.snap.enable = config.host.enableSnap;
  security.apparmor.enable = true;
}

{ config, lib, ... }:

{
  config = lib.mkIf config.host.enableSnap {
    services.snap.enable = true;
    security.apparmor.enable = true;
  };
}

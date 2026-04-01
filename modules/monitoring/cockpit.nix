{ config, lib, ... }:

lib.mkIf config.host.enableMonitoring {
  services.cockpit = {
    enable = true;
    port = 6969;
    settings.WebService.AllowUnencrypted = true;
  };
}

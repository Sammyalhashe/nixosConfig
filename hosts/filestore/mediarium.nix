{ config, lib, ... }:
let
  user = config.host.username;
in
{
  virtualisation.oci-containers.containers.mediarium = {
    image = "ghcr.io/rdborg/mediarium:latest";
    ports = [ "8264:8264" ];
    volumes = [
      "/mediarium/config:/config"
      # downloads, movies and tv share one mount so imports can hardlink
      "/mediarium/data:/data"
    ];
    environment = {
      PUID = "1001";
      PGID = "100";
      TZ = "America/New_York";
      # systemd restarts the container, so in-app "Update now" and Restart work
      MEDIARIUM_SUPERVISED = "1";
    };
    extraOptions = [ "--security-opt=no-new-privileges" ];
  };

  # an in-app update exits cleanly before restarting into the new version
  systemd.services.podman-mediarium.serviceConfig.Restart = lib.mkForce "always";

  systemd.tmpfiles.rules = [
    "d /mediarium 0755 ${user} users - -"
    "d /mediarium/config 0755 ${user} users - -"
    "d /mediarium/data 0755 ${user} users - -"
  ];

  networking.firewall.allowedTCPPorts = [ 8264 ];
}

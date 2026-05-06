{
  pkgs,
  lib,
  config,
  ...
}:

{
  virtualisation.oci-containers.backend = "podman";

  systemd.tmpfiles.rules = [
    "d /supernote/sndata/logs 0755 1000 1000 -"
    "d /supernote/sndata/logs/app 0755 1000 1000 -"
    "d /supernote/sndata/logs/cloud 0755 1000 1000 -"
    "d /supernote/sndata/logs/web 0755 1000 1000 -"
    "d /supernote/sndata/cert 0755 1000 1000 -"
    "d /supernote/sndata/convert 0755 1000 1000 -"
    "d /supernote/sndata/recycle 0755 1000 1000 -"
    "d /supernote/supernote_data 0755 1000 1000 -"
  ];

  # Containers
  virtualisation.oci-containers.containers."notelib" = {
    image = "docker.io/supernote/notelib:6.9.3";
    log-driver = "journald";
    extraOptions = [
      "--network-alias=notelib"
      "--network=supernote-net"
    ];
  };
  systemd.services."podman-notelib" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-supernote-net.service"
    ];
    requires = [
      "podman-network-supernote-net.service"
    ];
    partOf = [
      "podman-compose-supernote-cloud-root.target"
    ];
    wantedBy = [
      "podman-compose-supernote-cloud-root.target"
    ];
  };
  virtualisation.oci-containers.containers."supernote-mariadb" = {
    image = "mariadb:10.6.24";
    volumes = [
      "/supernote/sndata/db_data:/var/lib/mysql:rw"
      "/supernote/supernotedb.sql:/docker-entrypoint-initdb.d/supernotedb.sql:ro"
    ];
    cmd = [
      "--skip-name-resolve"
      "--bind-address=0.0.0.0"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=mariadb"
      "--network=supernote-net"
    ];
    environment = {
      MYSQL_DATABASE = "supernotedb";
      MYSQL_USER = "enote";
    };
    environmentFiles = [ config.sops.secrets.filestore_container_env.path ];
  };
  systemd.services."podman-supernote-mariadb" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-supernote-net.service"
      "supernote-db-init.service"
    ];
    requires = [
      "podman-network-supernote-net.service"
      "supernote-db-init.service"
    ];
    partOf = [
      "podman-compose-supernote-cloud-root.target"
    ];
    wantedBy = [
      "podman-compose-supernote-cloud-root.target"
    ];
  };

  systemd.services."supernote-db-init" = {
    description = "Download Supernote database schema if missing";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    before = [ "podman-supernote-mariadb.service" ];
    path = [ pkgs.curl ];
    wantedBy = [ "podman-compose-supernote-cloud-root.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    partOf = [ "podman-compose-supernote-cloud-root.target" ];
    script = ''
      if [ ! -f /supernote/supernotedb.sql ]; then
        curl -L https://supernote-private-cloud.supernote.com/cloud/supernotedb.sql -o /supernote/supernotedb.sql
        chown salhashemi2:users /supernote/supernotedb.sql
        chmod 644 /supernote/supernotedb.sql
      fi
    '';
  };
  virtualisation.oci-containers.containers."supernote-redis" = {
    image = "redis:7.4.7";
    volumes = [
      "/supernote/sndata/redis_data:/data:rw"
    ];
    cmd = [
      "redis-server"
      "--requirepass"
      "supernoteprivatecloud"
    ];
    log-driver = "journald";
    extraOptions = [
      "--health-cmd=redis-cli ping"
      "--health-interval=10s"
      "--health-retries=3"
      "--health-timeout=3s"
      "--network-alias=redis"
      "--network=supernote-net"
    ];
    environment = {
      REDIS_HOST = "supernote-redis";
      REDIS_PORT = "6379";
    };
  };
  systemd.services."podman-supernote-redis" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-supernote-net.service"
    ];
    requires = [
      "podman-network-supernote-net.service"
    ];
    partOf = [
      "podman-compose-supernote-cloud-root.target"
    ];
    wantedBy = [
      "podman-compose-supernote-cloud-root.target"
    ];
  };
  virtualisation.oci-containers.containers."supernote-service" = {
    image = "docker.io/supernote/supernote-service:26.02.23";
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "${builtins.toString ./../../certs/fullchain1.pem}:/etc/nginx/cert/server.crt:ro"
      "${config.sops.secrets.supernote_private_key.path}:/etc/nginx/cert/server.key:ro"
      "/supernote/sndata/convert:/home/supernote/convert:rw"
      "/supernote/sndata/logs/app:/home/supernote/logs:rw"
      "/supernote/sndata/logs/cloud:/home/supernote/cloud/logs:rw"
      "/supernote/sndata/logs/web:/var/log/nginx:rw"
      "/supernote/sndata/recycle:/home/supernote/recycle:rw"
      "/supernote/supernote_data:/home/supernote/data:rw"
    ];
    ports = [
      "19072:8080/tcp"
      "19443:443/tcp"
      "18072:18072/tcp"
    ];
    dependsOn = [
      "supernote-mariadb"
      "supernote-redis"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=supernote-service"
      "--network=supernote-net"
    ];
    environment = {
      DB_HOSTNAME = "mariadb";
      MYSQL_DATABASE = "supernotedb";
      MYSQL_USER = "enote";
      REDIS_HOST = "redis";
      REDIS_PASSWORD = "supernoteprivatecloud";
    };
    environmentFiles = [ config.sops.secrets.filestore_container_env.path ];
  };
  systemd.services."podman-supernote-service" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-supernote-net.service"
    ];
    requires = [
      "podman-network-supernote-net.service"
    ];
    partOf = [
      "podman-compose-supernote-cloud-root.target"
    ];
    wantedBy = [
      "podman-compose-supernote-cloud-root.target"
    ];
  };

  # Networks
  systemd.services."podman-network-supernote-net" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "podman network rm -f supernote-net";
    };
    script = ''
      podman network inspect supernote-net || podman network create supernote-net --driver=bridge
    '';
    partOf = [ "podman-compose-supernote-cloud-root.target" ];
    wantedBy = [ "podman-compose-supernote-cloud-root.target" ];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."podman-compose-supernote-cloud-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = [ "multi-user.target" ];
  };
}

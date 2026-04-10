{ config, lib, ... }:

lib.mkIf config.host.enableMonitoring {
  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      server.http_listen_port = 3100;
      common = {
        ring = {
          instance_addr = "127.0.0.1";
          kvstore.store = "inmemory";
        };
        replication_factor = 1;
        path_prefix = "/var/lib/loki";
      };

      schema_config.configs = [
        {
          from = "2023-01-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];

      storage_config.filesystem.directory = "/var/lib/loki/chunks";

      frontend.address = "127.0.0.1";

      # Single-node: disable memberlist clustering
      memberlist = {
        bind_addr = [ "127.0.0.1" ];
        advertise_addr = "127.0.0.1";
        abort_if_cluster_join_fails = false;
        join_members = [ ];
      };
    };
  };
}

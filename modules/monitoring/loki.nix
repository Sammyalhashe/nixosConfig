{ config, lib, ... }:

lib.mkIf config.host.enableMonitoring {
  services.grafana.provision.datasources.settings.datasources = [
    {
      name = "Loki";
      type = "loki";
      uid = "loki";
      url = "http://localhost:3100";
      isDefault = true;
    }
  ];

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      server.http_listen_port = 3100;

      common = {
        path_prefix = "/var/lib/loki";
        storage.filesystem.chunks_directory = "/var/lib/loki/chunks";
        storage.filesystem.rules_directory = "/var/lib/loki/rules";
        replication_factor = 1;
        instance_addr = "127.0.0.1";
        instance_interface_names = [ ];
        ring = {
          instance_addr = "127.0.0.1";
          kvstore.store = "inmemory";
        };
      };

      frontend.address = "127.0.0.1";

      # Single-node: disable memberlist clustering
      memberlist = {
        bind_addr = [ "127.0.0.1" ];
        advertise_addr = "127.0.0.1";
        abort_if_cluster_join_fails = false;
        join_members = [ ];
      };

      schema_config.configs = [
        {
          from = "2024-01-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];

      limits_config = {
        retention_period = "30d";
      };

      compactor = {
        working_directory = "/var/lib/loki/compactor";
        delete_request_store = "filesystem";
        retention_enabled = true;
      };
    };
  };
}

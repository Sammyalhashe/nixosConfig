{ config, lib, ... }:

lib.mkIf config.host.enableMonitoring {
  services.grafana.provision.datasources.settings.datasources = [
    {
      name = "Prometheus";
      type = "prometheus";
      uid = "prometheus";
      url = "http://localhost:9090";
    }
  ];

  services.prometheus = {
    enable = true;
    port = 9090;
    retentionTime = "30d";

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          { targets = [ "localhost:9100" ]; }
        ];
      }
    ];

    exporters.node = {
      enable = true;
      port = 9100;
      enabledCollectors = [
        "cpu"
        "diskstats"
        "filesystem"
        "loadavg"
        "meminfo"
        "netdev"
        "systemd"
        "time"
      ];
    };
  };
}

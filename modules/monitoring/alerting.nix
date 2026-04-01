{ config, lib, ... }:

lib.mkIf config.host.enableMonitoring {
  services.grafana.provision.alerting = {
    contactPoints.settings = {
      apiVersion = 1;
      contactPoints = [
        {
          orgId = 1;
          name = "Telegram";
          receivers = [
            {
              uid = "telegram";
              type = "telegram";
              settings = {
                bottoken = "$__file{/run/secrets/grafana_telegram_bot_token}";
                chatid = "8555669756";
              };
            }
          ];
        }
      ];
    };

    policies.settings = {
      apiVersion = 1;
      policies = [
        {
          orgId = 1;
          receiver = "Telegram";
          group_by = [ "alertname" ];
          group_wait = "30s";
          group_interval = "5m";
          repeat_interval = "4h";
        }
      ];
    };

    rules.settings = {
      apiVersion = 1;
      groups = [
        {
          orgId = 1;
          name = "Machine Health";
          folder = "Alerts";
          interval = "1m";
          rules = [
            {
              uid = "cpu-high";
              title = "CPU usage > 90%";
              condition = "C";
              for = "5m";
              data = [
                {
                  refId = "A";
                  datasourceUid = "prometheus";
                  model = {
                    expr = ''100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)'';
                    intervalMs = 1000;
                    maxDataPoints = 43200;
                  };
                  relativeTimeRange = { from = 600; to = 0; };
                }
                {
                  refId = "C";
                  datasourceUid = "__expr__";
                  model = {
                    type = "threshold";
                    expression = "A";
                    conditions = [
                      {
                        evaluator = { type = "gt"; params = [ 90 ]; };
                      }
                    ];
                  };
                  relativeTimeRange = { from = 0; to = 0; };
                }
              ];
              labels = { severity = "critical"; };
              annotations = {
                summary = "CPU usage is above 90% for 5 minutes";
              };
            }
            {
              uid = "memory-high";
              title = "Memory usage > 90%";
              condition = "C";
              for = "5m";
              data = [
                {
                  refId = "A";
                  datasourceUid = "prometheus";
                  model = {
                    expr = ''(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100'';
                    intervalMs = 1000;
                    maxDataPoints = 43200;
                  };
                  relativeTimeRange = { from = 600; to = 0; };
                }
                {
                  refId = "C";
                  datasourceUid = "__expr__";
                  model = {
                    type = "threshold";
                    expression = "A";
                    conditions = [
                      {
                        evaluator = { type = "gt"; params = [ 90 ]; };
                      }
                    ];
                  };
                  relativeTimeRange = { from = 0; to = 0; };
                }
              ];
              labels = { severity = "critical"; };
              annotations = {
                summary = "Memory usage is above 90% for 5 minutes";
              };
            }
            {
              uid = "disk-high";
              title = "Disk usage > 85%";
              condition = "C";
              for = "5m";
              data = [
                {
                  refId = "A";
                  datasourceUid = "prometheus";
                  model = {
                    expr = ''(1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100'';
                    intervalMs = 1000;
                    maxDataPoints = 43200;
                  };
                  relativeTimeRange = { from = 600; to = 0; };
                }
                {
                  refId = "C";
                  datasourceUid = "__expr__";
                  model = {
                    type = "threshold";
                    expression = "A";
                    conditions = [
                      {
                        evaluator = { type = "gt"; params = [ 85 ]; };
                      }
                    ];
                  };
                  relativeTimeRange = { from = 0; to = 0; };
                }
              ];
              labels = { severity = "warning"; };
              annotations = {
                summary = "Root disk usage is above 85% for 5 minutes";
              };
            }
            {
              uid = "node-exporter-down";
              title = "Node Exporter unreachable";
              condition = "C";
              for = "2m";
              data = [
                {
                  refId = "A";
                  datasourceUid = "prometheus";
                  model = {
                    expr = "up{job=\"node\"}";
                    intervalMs = 1000;
                    maxDataPoints = 43200;
                  };
                  relativeTimeRange = { from = 300; to = 0; };
                }
                {
                  refId = "C";
                  datasourceUid = "__expr__";
                  model = {
                    type = "threshold";
                    expression = "A";
                    conditions = [
                      {
                        evaluator = { type = "lt"; params = [ 1 ]; };
                      }
                    ];
                  };
                  relativeTimeRange = { from = 0; to = 0; };
                }
              ];
              labels = { severity = "critical"; };
              annotations = {
                summary = "Node Exporter is unreachable — metrics collection is down";
              };
            }
          ];
        }
        {
          orgId = 1;
          name = "Trading Bot";
          folder = "Alerts";
          interval = "1m";
          rules = [
            {
              uid = "trading-bot-errors";
              title = "Trading bot critical errors";
              condition = "C";
              for = "0s";
              data = [
                {
                  refId = "A";
                  datasourceUid = "loki";
                  model = {
                    expr = ''count_over_time({unit="coinbase-trader-ws.service"} |~ "CRITICAL|FATAL|Exception|Traceback" [5m])'';
                    intervalMs = 1000;
                    maxDataPoints = 43200;
                  };
                  relativeTimeRange = { from = 300; to = 0; };
                }
                {
                  refId = "C";
                  datasourceUid = "__expr__";
                  model = {
                    type = "threshold";
                    expression = "A";
                    conditions = [
                      {
                        evaluator = { type = "gt"; params = [ 0 ]; };
                      }
                    ];
                  };
                  relativeTimeRange = { from = 0; to = 0; };
                }
              ];
              labels = { severity = "critical"; };
              annotations = {
                summary = "Trading bot emitting critical errors or exceptions";
              };
            }
            {
              uid = "trading-bot-stopped";
              title = "Trading bot service failed";
              condition = "C";
              for = "0s";
              data = [
                {
                  refId = "A";
                  datasourceUid = "loki";
                  model = {
                    expr = ''count_over_time({unit="coinbase-trader-ws.service"} |= "Failed" [5m])'';
                    intervalMs = 1000;
                    maxDataPoints = 43200;
                  };
                  relativeTimeRange = { from = 300; to = 0; };
                }
                {
                  refId = "C";
                  datasourceUid = "__expr__";
                  model = {
                    type = "threshold";
                    expression = "A";
                    conditions = [
                      {
                        evaluator = { type = "gt"; params = [ 0 ]; };
                      }
                    ];
                  };
                  relativeTimeRange = { from = 0; to = 0; };
                }
              ];
              labels = { severity = "critical"; };
              annotations = {
                summary = "Trading bot service has failed or stopped";
              };
            }
          ];
        }
      ];
    };
  };
}

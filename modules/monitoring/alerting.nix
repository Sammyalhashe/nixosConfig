{ config, lib, ... }:

lib.mkIf config.host.enableMonitoring {
  sops.secrets.grafana_telegram_bot_token = {
    key = "telegram_bot_token";
    owner = "grafana";
  };

  services.grafana.provision = {
    alerting = {
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

      # The NixOS Grafana module has a bug where it generates literal "null" YAML
      # files if these settings are null, which makes Grafana fail on startup.
      # Setting these to an empty structure with apiVersion avoids this.
      templates.settings.apiVersion = 1;
      muteTimings.settings.apiVersion = 1;

      # Datasource UIDs ("loki"/"prometheus") are hardcoded in
      # modules/monitoring/grafana.nix, so rules can reference them directly
      # without depending on Grafana auto-generating and then resolving a
      # UID at startup.
      rules.settings = {
        apiVersion = 1;
        groups = [
          {
            orgId = 1;
            name = "Machine Health";
            folder = "Machine Health";
            interval = "1m";
            rules = [
              {
                uid = "cpu-high";
                title = "CPU usage > 90%";
                condition = "B";
                for = "5m";
                noDataState = "NoData";
                execErrState = "Alerting";
                data = [
                  {
                    refId = "A";
                    datasourceUid = "prometheus";
                    relativeTimeRange = {
                      from = 600;
                      to = 0;
                    };
                    model = {
                      refId = "A";
                      expr = ''100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)'';
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                    };
                  }
                  {
                    refId = "B";
                    datasourceUid = "__expr__";
                    relativeTimeRange = {
                      from = 0;
                      to = 0;
                    };
                    model = {
                      refId = "B";
                      type = "threshold";
                      expression = "A";
                      conditions = [
                        {
                          type = "query";
                          evaluator = {
                            type = "gt";
                            params = [ 90 ];
                          };
                        }
                      ];
                    };
                  }
                ];
                labels.severity = "warning";
                annotations.summary = "CPU usage has been above 90% for 5 minutes on {{ $labels.instance }}.";
              }
              {
                uid = "memory-high";
                title = "Memory usage > 90%";
                condition = "B";
                for = "5m";
                noDataState = "NoData";
                execErrState = "Alerting";
                data = [
                  {
                    refId = "A";
                    datasourceUid = "prometheus";
                    relativeTimeRange = {
                      from = 600;
                      to = 0;
                    };
                    model = {
                      refId = "A";
                      expr = "(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100";
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                    };
                  }
                  {
                    refId = "B";
                    datasourceUid = "__expr__";
                    relativeTimeRange = {
                      from = 0;
                      to = 0;
                    };
                    model = {
                      refId = "B";
                      type = "threshold";
                      expression = "A";
                      conditions = [
                        {
                          type = "query";
                          evaluator = {
                            type = "gt";
                            params = [ 90 ];
                          };
                        }
                      ];
                    };
                  }
                ];
                labels.severity = "warning";
                annotations.summary = "Memory usage has been above 90% for 5 minutes on {{ $labels.instance }}.";
              }
              {
                uid = "disk-high";
                title = "Disk usage > 85%";
                condition = "B";
                for = "5m";
                noDataState = "NoData";
                execErrState = "Alerting";
                data = [
                  {
                    refId = "A";
                    datasourceUid = "prometheus";
                    relativeTimeRange = {
                      from = 600;
                      to = 0;
                    };
                    model = {
                      refId = "A";
                      expr = ''100 - (node_filesystem_avail_bytes{mountpoint="/",fstype!="tmpfs"} / node_filesystem_size_bytes{mountpoint="/",fstype!="tmpfs"} * 100)'';
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                    };
                  }
                  {
                    refId = "B";
                    datasourceUid = "__expr__";
                    relativeTimeRange = {
                      from = 0;
                      to = 0;
                    };
                    model = {
                      refId = "B";
                      type = "threshold";
                      expression = "A";
                      conditions = [
                        {
                          type = "query";
                          evaluator = {
                            type = "gt";
                            params = [ 85 ];
                          };
                        }
                      ];
                    };
                  }
                ];
                labels.severity = "warning";
                annotations.summary = "Root filesystem usage has been above 85% for 5 minutes on {{ $labels.instance }}.";
              }
              {
                uid = "node-exporter-down";
                title = "Node Exporter down";
                condition = "B";
                for = "2m";
                noDataState = "NoData";
                execErrState = "Alerting";
                data = [
                  {
                    refId = "A";
                    datasourceUid = "prometheus";
                    relativeTimeRange = {
                      from = 300;
                      to = 0;
                    };
                    model = {
                      refId = "A";
                      expr = ''up{job="node"}'';
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                    };
                  }
                  {
                    refId = "B";
                    datasourceUid = "__expr__";
                    relativeTimeRange = {
                      from = 0;
                      to = 0;
                    };
                    model = {
                      refId = "B";
                      type = "threshold";
                      expression = "A";
                      conditions = [
                        {
                          type = "query";
                          evaluator = {
                            type = "lt";
                            params = [ 1 ];
                          };
                        }
                      ];
                    };
                  }
                ];
                labels.severity = "critical";
                annotations.summary = "Prometheus has not been able to scrape node_exporter on {{ $labels.instance }} for 2 minutes.";
              }
            ];
          }
          {
            orgId = 1;
            name = "Trading Bot";
            folder = "Trading Bot";
            interval = "1m";
            rules = [
              {
                uid = "trading-bot-critical-errors";
                title = "Trading bot critical errors";
                condition = "B";
                for = "1m";
                noDataState = "NoData";
                execErrState = "Alerting";
                data = [
                  {
                    refId = "A";
                    datasourceUid = "loki";
                    relativeTimeRange = {
                      from = 300;
                      to = 0;
                    };
                    model = {
                      refId = "A";
                      queryType = "instant";
                      expr = ''count_over_time({unit="coinbase-trader-ws.service"} |~ "CRITICAL|FATAL|Exception|Traceback" [5m])'';
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                    };
                  }
                  {
                    refId = "B";
                    datasourceUid = "__expr__";
                    relativeTimeRange = {
                      from = 0;
                      to = 0;
                    };
                    model = {
                      refId = "B";
                      type = "threshold";
                      expression = "A";
                      conditions = [
                        {
                          type = "query";
                          evaluator = {
                            type = "gt";
                            params = [ 0 ];
                          };
                        }
                      ];
                    };
                  }
                ];
                labels.severity = "critical";
                annotations.summary = "coinbase-trader-ws.service logged a CRITICAL/FATAL/Exception/Traceback line in the last 5 minutes.";
              }
              {
                uid = "trading-bot-service-failed";
                title = "Trading bot service failed";
                condition = "B";
                for = "1m";
                noDataState = "NoData";
                execErrState = "Alerting";
                data = [
                  {
                    refId = "A";
                    datasourceUid = "loki";
                    relativeTimeRange = {
                      from = 300;
                      to = 0;
                    };
                    model = {
                      refId = "A";
                      queryType = "instant";
                      expr = ''count_over_time({unit="coinbase-trader-ws.service"} |= "Failed" [5m])'';
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                    };
                  }
                  {
                    refId = "B";
                    datasourceUid = "__expr__";
                    relativeTimeRange = {
                      from = 0;
                      to = 0;
                    };
                    model = {
                      refId = "B";
                      type = "threshold";
                      expression = "A";
                      conditions = [
                        {
                          type = "query";
                          evaluator = {
                            type = "gt";
                            params = [ 0 ];
                          };
                        }
                      ];
                    };
                  }
                ];
                labels.severity = "critical";
                annotations.summary = "coinbase-trader-ws.service logged a \"Failed\" line in the last 5 minutes.";
              }
            ];
          }
        ];
      };
    };
  };
}

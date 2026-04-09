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

      # The NixOS Grafana module's generateAlertingProvisioningYaml lacks a
      # null-guard: when rules/templates/muteTimings are unset their settings
      # default to null, producing a literal "null" YAML document that makes
      # Grafana fail on startup. Provide explicit empty structures to avoid this.
      rules.settings = {
        apiVersion = 1;
        groups = [];
      };
      templates.settings = {
        apiVersion = 1;
      };
      muteTimings.settings = {
        apiVersion = 1;
        muteTimes = [];
      };
    };
  };

  # Alert rules are created via the Grafana UI (Alerting > Alert rules)
  # rather than file provisioning, to avoid datasource UID resolution
  # issues at startup.
  #
  # Rules to create manually:
  #   Machine Health (Prometheus):
  #     - CPU > 90% for 5m
  #     - Memory > 90% for 5m
  #     - Disk > 85% for 5m
  #     - Node Exporter down for 2m
  #   Trading Bot (Loki):
  #     - Critical errors: {unit="coinbase-trader-ws.service"} |~ "CRITICAL|FATAL|Exception|Traceback"
  #     - Service failed: {unit="coinbase-trader-ws.service"} |= "Failed"
}

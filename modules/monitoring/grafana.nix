{ config, pkgs, lib, ... }:

lib.mkIf config.host.enableMonitoring {
  # Generate Grafana secret key if it doesn't exist
  systemd.tmpfiles.rules = [
    "d /var/lib/grafana 0750 grafana grafana -"
  ];
  system.activationScripts.grafana-secret-key = ''
    if [ ! -f /var/lib/grafana/secret_key ]; then
      mkdir -p /var/lib/grafana
      ${pkgs.openssl}/bin/openssl rand -hex 32 > /var/lib/grafana/secret_key
      chmod 400 /var/lib/grafana/secret_key
      chown grafana:grafana /var/lib/grafana/secret_key 2>/dev/null || true
    fi
  '';

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
      };
      security.secret_key = "$__file{/var/lib/grafana/secret_key}";
      # Disable login requirement for local use
      "auth.anonymous" = {
        enabled = true;
        org_role = "Admin";
      };
    };
    provision = {
      datasources.settings.datasources = [
        {
          name = "Loki";
          type = "loki";
          uid = "loki";
          url = "http://localhost:3100";
          isDefault = true;
        }
        {
          name = "Prometheus";
          type = "prometheus";
          uid = "prometheus";
          url = "http://localhost:9090";
        }
      ];
      dashboards.settings.providers = [
        {
          name = "default";
          options.path = ./dashboards;
        }
      ];
    };
  };
}

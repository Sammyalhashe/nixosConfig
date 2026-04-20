{ config, lib, pkgs, ... }:

lib.mkIf config.host.enableMonitoring {
  services.alloy = {
    enable = true;
    extraFlags = [
      "--server.http.listen-addr=127.0.0.1:9080"
    ];
  };

  environment.etc."alloy/config.alloy".text = ''
    loki.relabel "journal" {
      forward_to = []

      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }

      rule {
        source_labels = ["__journal__systemd_user_unit"]
        target_label  = "user_unit"
      }

      rule {
        source_labels = ["__journal_priority_keyword"]
        target_label  = "priority"
      }
    }

    loki.source.journal "systemd" {
      forward_to    = [loki.write.local.receiver]
      relabel_rules = loki.relabel.journal.rules
      max_age       = "12h"
      labels        = {
        job  = "systemd-journal",
        host = "${config.networking.hostName}",
      }
    }

    loki.write "local" {
      endpoint {
        url = "http://localhost:3100/loki/api/v1/push"
      }
    }
  '';
}

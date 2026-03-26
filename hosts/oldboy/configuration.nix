{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  user = "salhashemi2";
in
{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
    ../../common/home-manager-config.nix
    ../../modules
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 1;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "oldboy"; # Define your hostname.

  host.isHeadless = true;

  # Thermal management for lid-closed operation
  services.thermald.enable = true;

  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;
  networking.networkmanager.wifi.scanRandMacAddress = false;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.${user} = {
    isNormalUser = true;
    description = "Sammy Al Hashemi";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    packages = with pkgs; [ ];
  };

  # prevent the laptop from hibernating when lid is closed
  services.getty.autologinUser = "${user}";

  services.logind.lidSwitch = "ignore";
  services.logind.lidSwitchExternalPower = "ignore";
  services.logind.lidSwitchDocked = "ignore";

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

  # Firewall
  networking.firewall.allowedTCPPorts = [
    6969 # Cockpit
    3000 # Grafana
    3100 # Loki
  ];

  # Cockpit web-based server management UI
  services.cockpit = {
    enable = true;
    port = 6969;
    settings.WebService.AllowUnencrypted = true;
  };

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

  # Grafana - log visualization and dashboards
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
          url = "http://localhost:3100";
          isDefault = true;
        }
      ];
    };
  };

  # Loki - log aggregation backend
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
        ring = {
          instance_addr = "127.0.0.1";
          kvstore.store = "inmemory";
        };
      };

      # Single-node: disable memberlist clustering
      memberlist.join_members = [ ];

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

  # Promtail - log shipper (scrapes journald and sends to Loki)
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 9080;
        grpc_listen_port = 0;
      };
      positions.filename = "/var/lib/promtail/positions.yaml";
      clients = [
        { url = "http://localhost:3100/loki/api/v1/push"; }
      ];
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = "oldboy";
            };
          };
          relabel_configs = [
            {
              source_labels = [ "__journal__systemd_unit" ];
              target_label = "unit";
            }
            {
              source_labels = [ "__journal__systemd_user_unit" ];
              target_label = "user_unit";
            }
            {
              source_labels = [ "__journal_priority_keyword" ];
              target_label = "priority";
            }
          ];
        }
      ];
    };
  };
}

{
  config,
  pkgs,
  lib,
  inputs,
  ...}: ...
    services.syncthing = {
      enable = true;
      user = "salhashemi2";
      dataDir = "/mnt/logseq-data"; # Default directory for new folders
      configDir = "/home/salhashemi2/.config/syncthing"; # Settings storage
      guiAddress = "0.0.0.0:8384"; # Web UI accessible on your network

      overrideDevices = false;
      overrideFolders = false;

      # Open default ports (22000 for sync, 21027 for discovery)
      openDefaultPorts = true;

      settings = {
        gui = {
          user = "salhashemi2";
          password = "***REMOVED***"; # Set your own password
        };

        # Folders to sync
        folders = {
          "Logseq-Notes" = {
            # This points directly to your new SSD
            path = "/mnt/logseq-data/Logseq";
            # Once you add your phone/laptop in the Web UI,
            # you can add their Device IDs here later.
            devices = [ ];
            versioning = {
              type = "staggered";
              params = {
                cleanInterval = "3600";
                maxAge = "15552000"; # Keep 180 days of history
              };
            };
          };
        };
      };
    };

    services.forgejo = {
      enable = true;
      stateDir = "/mnt/logseq-data/forgejo";
      database.type = "postgres";
      settings.server = {
        DOMAIN = "git.salh.xyz";
        ROOT_URL = "https://git.salh.xyz/";
        HTTP_PORT = 3000;
      };
    };

    services.postgresql = {
      enable = true;
      # Ensure the path is exactly what Postgres expects
      dataDir = "/mnt/logseq-data/postgresql/${config.services.postgresql.package.psqlSchema}";
      authentication = lib.mkOverride 10 ''
        local all all trust
      '';
    };

    # Override Systemd sandboxing to allow access to /mnt
    systemd.services.postgresql.serviceConfig = {
      ProtectHome = lib.mkForce "tmpfs";
      ReadWritePaths = [ "/mnt/logseq-data/postgresql" ];
    };

    # Nginx Reverse Proxy (as before)
    # services.nginx.virtualHosts."git.salh.xyz" = {
    #   enableACME = true;
    #   forceSSL = true;
    #   locations."/" = {
    #     proxyPass = "http://127.0.0.1:3000";
    #   };
    # };

    users = {
      mutableUsers = false;
      users."${user}" = {
        isNormalUser = true;
        password = password; # This was changed from passwordFile to password
        extraGroups = [
          "wheel"
          "podman"
        ];
      };
    };

    programs.bash.interactiveShellInit = ''
      ${health-check}/bin/sys-health
    '';

    services.restic.backups.logseq = {
      paths = [ "/mnt/logseq-data" ];
      repository = "/home/salhashemi2/logseq_backup";
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
      passwordFile = "/etc/nixos/restic-password";
      # Keep 7 daily, 4 weekly, and 6 monthly backups
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
      ];

      # This ensures the init script runs first
      extraOptions = [ "--network=host" ]; # If you eventually move to cloud backups
    };

    systemd.services.restic-backups-logseq.after = [ "restic-repo-init.service" ];
    systemd.services.restic-backups-logseq.requires = [ "restic-repo-init.service" ];

    systemd.services.forgejo-secrets = {
      preStart = ''
        mkdir -p /mnt/logseq-data/forgejo/custom/conf
        chown -R forgejo:forgejo /mnt/logseq-data/forgejo
        chmod -R 750 /mnt/logseq-data/forgejo
      '';
      # This makes the service wait until the SSD is actually mounted
      unitConfig.RequiresMountsFor = "/mnt/logseq-data";
    };

    systemd.services.restic-repo-init = {
      description = "Initialize Restic repository if it doesn't exist";
      before = [ "restic-backups-logseq.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        if [ ! -f /home/salhashemi2/logseq_backup/config ]; then
          echo "Repository not found. Initializing..."
          mkdir -p /home/salhashemi2/logseq_backup
          # Use the password file defined in your main restic config
          ${pkgs.restic}/bin/restic init \
            --repo /home/salhashemi2/logseq_backup \
            --password-file /etc/nixos/restic-password
        else
          echo "Repository already initialized."
        fi
      '';
    };

    hardware.enableRedistributableFirmware = true;
    system.stateVersion = "23.11";
}
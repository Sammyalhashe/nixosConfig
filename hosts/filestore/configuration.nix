{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  user = "salhashemi2";
  interface = "wlan0";
  hostname = "filestore";

  # 1. Define the Python environment (Pinned to 3.12 for pysn-digest compatibility)
  pysnEnv = pkgs.python312.withPackages (
    ps: with ps; [
      pillow
      setuptools
      # aiofiles
      # aiohttp
      # beautifulsoup4
      # numpy
      # opencv4
      # pandas
      # pdf2image
      # pymupdf
      # pystray
      # pytz
      # pyyaml
      # requests
      # svglib
      # tqdm
      # reportlab
      # openai
      # google-generativeai
      # anthropic
    ]
  );

  # Backup script for Vaultwarden SQLite DB
  vaultwardenBackupScript = pkgs.writeShellScriptBin "vaultwarden-sqlite-backup" ''
    #!/usr/bin/env bash
    set -euo pipefail
    BACKUP_DIR="/backup/vaultwarden"
    mkdir -p "$BACKUP_DIR"
    TIMESTAMP=$(date +"%Y-%m-%dT%H-%M-%S")
    BACKUP_FILE="$BACKUP_DIR/vaultwarden-$TIMESTAMP.sqlite3"
    ${pkgs.podman}/bin/podman exec vaultwarden sqlite3 /data/db.sqlite3 ".backup \"$BACKUP_FILE\""
  '';

  # HACS download wrapper script
  hacsDownloadScript = pkgs.writeShellScriptBin "hacs-download-wrapper" ''
    #!/usr/bin/env bash
    set -euo pipefail
    HACS_DIR="/config/custom_components/hacs"
    if ${pkgs.podman}/bin/podman exec homeassistant test -d "$HACS_DIR"; then
      echo "HACS already installed – skipping download"
      exit 0
    fi
    echo "Downloading HACS..."
    ${pkgs.podman}/bin/podman exec homeassistant wget -O - https://get.hacs.xyz | bash -
  '';

  # Define the sync script
  logseq-supernote-sync = pkgs.writeShellScriptBin "logseq-sync" ''
    # Paths (Using environment variables or hardcoded Nix paths)
    LOGSEQ_DIR="/Logseq/journals"
    OUTPUT_DIR="/SupernoteSync/Digests"
    TODAY=$(date +%Y_%m_%d)
    TARGET_NOTE="$LOGSEQ_DIR/$TODAY.md"

    mkdir -p "$OUTPUT_DIR"

    if [ -f "$TARGET_NOTE" ]; then
        echo "Processing today's journal: $TARGET_NOTE"
        # Call the tool (it will be in the path thanks to the service config below)
        pysn-digest --input "$TARGET_NOTE" --output "$OUTPUT_DIR/$TODAY-digest.pdf"
    else
        echo "No journal entry found for today yet."
    fi
  '';
in
{
  time.timeZone = "America/New_York";
  nix.gc.options = lib.mkForce "--delete-older-than 14d";

  # This deduplicates files that are identical across different packages
  nix.settings.auto-optimise-store = true;
  nix.settings.trusted-users = [
    "root"
    "salhashemi2"
  ];

  imports = [
    inputs.home-manager.nixosModules.default
    ../../common/home-manager-config.nix
    inputs.sops-nix.nixosModules.sops
  ];

  # OpenClaw Gateway Configuration (Added by OpenClaw Agent)
  # services.openclaw.gateway.settings = {
  #   web.braveApiKey = "REPLACED_BY_SOPS";
  # };

  sops.secrets.filestore_user_password = { };
  sops.secrets.filestore_password_hash = { };
  sops.secrets.filestore_wifi_ssid = { };
  sops.secrets.filestore_wifi_env = {
    owner = "wpa_supplicant";
  };
  sops.secrets.filestore_container_env = { };
  sops.secrets.supernote_email = {
    owner = "salhashemi2";
  };
  sops.secrets.supernote_password = {
    owner = "salhashemi2";
  };

  documentation.enable = false;
  documentation.man.enable = false;
  documentation.nixos.enable = false;

  host.homeManagerHostname = "filestore";

  # Stylix Configuration (Headless/Minimal)
  stylix =
    # let
    #   theme = import ../../common/stylix-values.nix { inherit pkgs; };
    # in
    {
      enable = lib.mkForce false;
      # base16Scheme = theme.base16Scheme;
      # polarity = theme.polarity;
      # fonts = theme.fonts;

      # Disable graphical targets to save space/dependencies
      targets.gtk.enable = false;
      targets.gnome.enable = false;
      targets.lightdm.enable = false;
    };

  # Add a safety cushion (Swap File)
  # swapDevices = [{
  #   device = "/var/lib/swapfile";
  #   size = 2048; # 2GB in MiB
  # }];
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];
  boot = {
    # Using linuxPackages_rpi4 instead of pkgs.linuxKernel.packages.linux_rpi4
    # to silence the "linux-rpi series will be removed" evaluation warning.
    kernelPackages = pkgs.linuxPackages_rpi4;
    initrd.availableKernelModules = [
      "xhci_pci"
      "usbhid"
      "usb_storage"
    ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  networking = {
    hostName = hostname;
    wireless = {
      enable = true;
      networks."146WIFISt".psk = "Rfin1ihe!";
      interfaces = [ interface ];
    };
    # Static IP on wlan0
    interfaces.${interface} = {
      ipv4.addresses = [
        {
          address = "11.125.37.98";
          prefixLength = 24;
        }
      ];
      ipv4.routes = [
        {
          address = "10.139.112.0";
          prefixLength = 24;
          via = "11.125.37.99";
        }
      ];
    };
    defaultGateway = "11.125.37.1"; # Your router IP
    nameservers = [
      "11.125.37.99"
      "11.125.37.1"
      "1.1.1.1"
    ];
  };

  # Add this to move container data to the SSD
  virtualisation.containers.storage.settings = {
    storage = {
      driver = "overlay";
      graphroot = "/podman-storage";
    };
  };

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true; # Enables `docker` alias → podman
      defaultNetwork.settings.dns_enabled = true; # Container DNS
    };
    oci-containers = {
      backend = "podman";
      containers.portainer = {
        image = "docker.io/portainer/portainer-ce:latest";
        ports = [
          "9443:9443"
          "9000:9000"
          "8000:8000"
          "8080:80"
        ];
        volumes = [
          "portainer_data:/data"
          "/run/podman/podman.sock:/run/podman/podman.sock" # ← Socket for control
          "/run/podman/podman.sock:/var/run/docker.sock"
        ];
      };
      containers.nginx-proxy-manager = {
        image = "jc21/nginx-proxy-manager:latest";
        ports = [
          "80:80" # HTTP → HTTPS redirect
          "443:443" # HTTPS
          "81:81" # NPM admin UI
        ];
        volumes = [
          "npm-app:/data"
          "npm-ssl:/etc/letsencrypt"
          "npm-db:/data/database"
        ];
        # extraOptions = [ "--network=host" ];
      };
      containers.vaultwarden = {
        image = "vaultwarden/server:latest";
        ports = [ "8090:80" ]; # Vaultwarden internal 80 → host 8090
        volumes = [ "vw-data:/data" ];
        environment = {
          # Required for SSO
          DOMAIN = "https://vaultwarden.salh.xyz";
          SSO_ENABLED = "true";
          SSO_AUTHORITY = "https://auth.salh.xyz/application/o/vaultwarden/";
          SSO_CLIENT_ID = "UajP2X0awwcJmWUVs8eTtWofWir4Ks3GNFgzam4X";
          SSO_SCOPES = "openid profile email offline_access vaultwarden";
          SSO_PKCE = "true";
          SSO_ROLES_ENABLED = "true";
          SSO_ROLES_DEFAULT_TO_USER = "true";

          # Optional: allow new users to sign up via SSO even if SIGNUPS_ALLOWED is false
          SSO_SIGNUPS_MATCH_EMAIL = "true";
        };
        environmentFiles = [ config.sops.secrets.filestore_container_env.path ];
      };
    };
  };

  # Backup Vaultwarden SQLite DB using sqlite3 .backup
  systemd.services.vaultwarden-backup = {
    description = "Backup Vaultwarden SQLite database";
    after = [
      "network.target"
      "podman.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${vaultwardenBackupScript}/bin/vaultwarden-sqlite-backup";
    };
  };

  systemd.timers.vaultwarden-backup = {
    description = "Timer for Vaultwarden backup";
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  virtualisation.oci-containers.containers = {
    # 1. The Database (Sane limits for Pi 4)
    nextcloud-db = {
      image = "docker.io/library/postgres:16-alpine";
      # Lower connections to prevent RAM exhaustion, but enough for the job
      cmd = [
        "postgres"
        "-c"
        "max_connections=100"
        "-c"
        "shared_buffers=512MB" # Assuming 4GB or 8GB Pi
      ];
      environment = {
        POSTGRES_DB = "nextcloud";
        POSTGRES_USER = "nextcloud";
      };
      environmentFiles = [ config.sops.secrets.filestore_container_env.path ];
      volumes = [ "/nextcloud/db:/var/lib/postgresql/data" ];
      extraOptions = [ "--network=nextcloud-net" ];
    };

    # 2. Redis (MANDATORY for Pi 4)
    nextcloud-redis = {
      image = "docker.io/library/redis:alpine";
      extraOptions = [ "--network=nextcloud-net" ];
    };

    # 3. Nextcloud App
    nextcloud-app = {
      image = "docker.io/library/nextcloud:33.0.0-apache";
      ports = [ "8082:80" ];
      volumes = [
        "/nextcloud/html:/var/www/html"
        "/nextcloud/data:/var/www/html/data"
        "/nextcloud/config:/var/www/html/config"
      ];
      environment = {
        POSTGRES_HOST = "nextcloud-db";
        POSTGRES_DB = "nextcloud";
        POSTGRES_USER = "nextcloud";
        REDIS_HOST = "nextcloud-redis";

        # Pi 4 sweet spot: 1GB is enough for scans, 2GB if you have the 8GB Pi.
        PHP_MEMORY_LIMIT = "1G";
        PHP_UPLOAD_LIMIT = "10G";

        # Optimization: Disable heavy background tasks during migration
        NEXTCLOUD_TRUSTED_DOMAINS = "cloud.salh.xyz";
        OVERWRITEPROTOCOL = "https";
        OVERWRITEHOST = "cloud.salh.xyz";
      };
      environmentFiles = [ config.sops.secrets.filestore_container_env.path ];
      extraOptions = [ "--network=nextcloud-net" ];
    };

    homeassistant = {
      image = "ghcr.io/home-assistant/home-assistant:stable";
      volumes = [
        "/homeassistant:/config"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        TZ = "America/New_York"; # Set your timezone
      };
      ports = [ "8123:8123" ];
      extraOptions = [ "--network=hass-net" ];
    };
  };

  systemd.services.init-hass-network = {

    description = "Create the internal network for Home Assistant";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.podman}/bin/podman network exists hass-net || \
      ${pkgs.podman}/bin/podman network create hass-net
    '';
  };

  systemd.services.hacs-download = {
    description = "Download and install HACS into Home Assistant";
    after = [ "podman-homeassistant.service" ];
    wants = [ "podman-homeassistant.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${hacsDownloadScript}/bin/hacs-download-wrapper";
    };
  };

  systemd.services.init-nextcloud-network = {
    description = "Create the internal network for Nextcloud";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.podman}/bin/podman network exists nextcloud-net || \
      ${pkgs.podman}/bin/podman network create nextcloud-net
    '';
  };

  # Ensure containers wait for the network
  systemd.services."podman-nextcloud-db" = {
    after = [ "init-nextcloud-network.service" ];
    requires = [ "init-nextcloud-network.service" ];
  };
  systemd.services."podman-nextcloud-redis" = {
    after = [ "init-nextcloud-network.service" ];
    requires = [ "init-nextcloud-network.service" ];
  };
  systemd.services."podman-nextcloud-app" = {
    after = [
      "init-nextcloud-network.service"
      "podman-nextcloud-db.service"
      "podman-nextcloud-redis.service"
    ];
    requires = [
      "init-nextcloud-network.service"
      "podman-nextcloud-redis.service"
    ];
  };

  # Nextcloud Background Jobs (Cron)
  systemd.services.nextcloud-cron = {
    description = "Nextcloud cron job";
    after = [ "podman-nextcloud-app.service" ];
    requires = [ "podman-nextcloud-app.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.podman}/bin/podman exec -u 33 nextcloud-app php -f cron.php
    '';
  };

  systemd.timers.nextcloud-cron = {
    description = "Run Nextcloud cron job every 5 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/5";
      Persistent = true;
    };
  };

  networking.firewall.allowedTCPPorts = [
    9443
    9000
    8000
    80
    81
    443
    8384
    3000
    22000
    18789
    22
  ];
  networking.firewall.allowedUDPPorts = [
    22000
    21027
  ];
  networking.firewall.extraCommands = ''
    iptables -t filter -I INPUT 1 -p tcp --dport 443 -j ACCEPT
    iptables -t filter -I INPUT 2 -p tcp --dport 80 -j ACCEPT
    iptables -t filter -I INPUT 3 -p tcp --dport 81 -j ACCEPT
    # Allow outgoing SSH to any destination
    iptables -t filter -I OUTPUT 1 -p tcp --dport 22 -j ACCEPT
  '';

  systemd.tmpfiles.rules = [
    # Type | Path             | Mode | User         | Group | Age | Argument
    "d /SupernoteSync/Digests 0755 salhashemi2 users - -"
    "d /postgresql 0700 postgres postgres -"
    # Explicitly creating the deep path Forgejo needs for its keys
    "d /forgejo 0750 forgejo forgejo -"
    "d /forgejo/custom 0750 forgejo forgejo -"
    "d /forgejo/custom/conf 0770 forgejo forgejo -" # Slightly looser for the bootstrap

    "d /nextcloud 0755 salhashemi2 users - -"
    "d /nextcloud/html 0755 33 33 - -" # 33 is the standard 'www-data' user in containers
    "d /nextcloud/data 0755 33 33 - -"
    "d /nextcloud/config 0755 33 33 - -"

    "d /nextcloud 0755 salhashemi2 users - -"
    "z /nextcloud/html 0755 33 33 - -"
    "z /nextcloud/data 0755 33 33 - -"
    "z /nextcloud/config 0755 33 33 - -"

    # Database Folder (UID 70 is postgres inside the container)
    # 'd' creates it if missing; 'z' ensures the ownership recursively
    "d /nextcloud/db 0700 70 70 - -"
    "z /nextcloud/db 0700 70 70 - -"

    "d /homeassistant 0755 salhashemi2 users - -"

    # Purge files in /tmp older than 1 day
    "q /tmp 1777 root root 1d -"
  ];

  environment.systemPackages = with pkgs; [
    nmap
    openssl
    logseq-supernote-sync
    nodejs_25
    btop
    gemini-cli
    python3
  ];

  environment.variables = {
    COINBASE_API_KEY_Clawdbot = "/var/lib/private/coinbase_clawdbot2/api_key_id";
    COINBASE_API_SECRET_Clawdbot = "/var/lib/private/coinbase_clawdbot2/api_secret";
  };

  # Enable zRam swap
  zramSwap = {
    enable = true;
    algorithm = "zstd"; # High compression ratio, great for C++ devs
    memoryPercent = 50; # Use up to 4GB of your 8GB RAM as a compressed swap
  };

  # Help the kernel decide when to swap
  boot.kernel.sysctl = {
    "vm.swappiness" = 100; # With zRam, you WANT the kernel to swap early and often
    "vm.dirty_ratio" = 10; # Force writes to the SD card to happen in smaller, more frequent bursts
    "vm.dirty_background_ratio" = 5;
  };

  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true;
      AllowTcpForwarding = true; # Required for the X11 tunnel
    };
  };

  services.syncthing = {
    enable = true;
    user = "salhashemi2";
    dataDir = "/home/salhashemi2"; # Default directory for new folders
    configDir = "/home/salhashemi2/.config/syncthing"; # Settings storage
    guiAddress = "0.0.0.0:8384"; # Web UI accessible on your network

    overrideDevices = false;
    overrideFolders = false;

    # Open default ports (22000 for sync, 21027 for discovery)
    openDefaultPorts = true;

    settings = {
      gui = {
        user = "salhashemi2";
        password = "Rfin1ihe!";
      };

      # Folders to sync
      folders = {
        "Logseq-Notes" = {
          # This points directly to your new SSD folder
          path = "/Logseq";
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
    stateDir = "/forgejo";
    database.type = "postgres";
    settings.server = {
      DOMAIN = "git.salh.xyz";
      ROOT_URL = "https://git.salh.xyz/";
      HTTP_PORT = 3000;
    };
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    # Ensure the path is exactly what Postgres expects
    dataDir = "/postgresql/16";
    authentication = lib.mkOverride 10 ''
      local all all trust
    '';
  };

  # Override Systemd sandboxing to allow access to /mnt
  systemd.services.postgresql.serviceConfig = {
    ProtectHome = lib.mkForce "tmpfs";
    ReadWritePaths = [ "/postgresql" ];
  };

  users.mutableUsers = false;
  security.sudo.wheelNeedsPassword = false;
  users.users."${user}" = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.filestore_password_hash.path;
    extraGroups = [
      "wheel"
      "podman"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINUptk+nhbHYTfUJvGT3/X4vkKWRotT5ckw8BiQuADml sammy@salh.xyz"
    ];
  };

  # services.restic.backups.logseq = {
  #   paths = [ "/logseq-data" ];
  #   repository = "/home/salhashemi2/logseq_backup";
  #   timerConfig = {
  #     OnCalendar = "daily";
  #     Persistent = true;
  #   };
  #   passwordFile = "/etc/nixos/restic-password";
  #   # Keep 7 daily, 4 weekly, and 6 monthly backups
  #   pruneOpts = [
  #     "--keep-daily 7"
  #     "--keep-weekly 4"
  #     "--keep-monthly 6"
  #   ];
  #
  #   # This ensures the init script runs first
  #   extraOptions = [ "--network=host" ]; # If you eventually move to cloud backups
  # };
  #
  # systemd.services.restic-backups-logseq.after = [ "restic-repo-init.service" ];
  # systemd.services.restic-backups-logseq.requires = [ "restic-repo-init.service" ];

  systemd.services.forgejo-secrets = {
    description = "Forgejo secret bootstrap helper";
    wantedBy = [ "multi-user.target" ];
    before = [ "forgejo.service" ];
    serviceConfig.Type = "oneshot";
    preStart = ''
      mkdir -p /forgejo/custom/conf
      chown -hR forgejo:forgejo /forgejo || true
      chmod -R 750 /forgejo || true
    '';
    script = "true";
  };
  programs.dconf.enable = true;
  hardware.enableRedistributableFirmware = true;
  system.stateVersion = "23.11";
}

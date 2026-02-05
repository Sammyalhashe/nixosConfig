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

  health-check = pkgs.writeShellScriptBin "sys-health" ''
    echo "--- Systemd Service Health ---"
    SERVICES="syncthing.service nginx.service logseq-digest.timer"

    for svc in $SERVICES; do
      status=$(systemctl is-active "$svc")
      if [ "$status" = "active" ]; then
        echo "✅ $svc: $status"
      else
        echo "❌ $svc: $status"
      fi
    done

    # Check for any failed services across the whole system
    FAILED_COUNT=$(systemctl list-units --state=failed --no-legend | wc -l)
    if [ "$FAILED_COUNT" -gt 0 ]; then
      echo "⚠️  Alert: $FAILED_COUNT services have FAILED!"
      systemctl list-units --state=failed --no-legend
    fi

    # Check Podman/Docker pods if they exist
    if command -v podman &> /dev/null; then
      echo -e "\n--- Container/Pod Health ---"
      podman ps --format \"{{.Names}}: {{.Status}}\" | sed 's/^/📦 /'
    fi

    echo -e "\n--- Storage Health ---"
    df -h / | grep -v Filesystem

    echo -e "\n--- Last Logseq Sync ---"
    systemctl --user list-timers logseq-digest.timer --no-legend
  '';

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

  # 2. The Extraction Script (Embedded Python)
  # This script pulls TODOs from your Logseq Journals on your SSD
  extractTodos = pkgs.writeScriptBin "extract-logseq-todos" ''
    #!${pysnEnv}/bin/python
    import re
    from datetime import date
    from pathlib import Path

    LOGSEQ_JOURNALS = Path("/Logseq/journals")
    OUTPUT_MD = Path("/tmp/daily_focus.md")

    def extract():
        today_file = LOGSEQ_JOURNALS / f"{date.today().strftime('%Y_%m_%d')}.md"
        if not today_file.exists():
            OUTPUT_MD.write_text("# Daily Focus\n\nNo journal entry found for today.")
            return
        
        content = today_file.read_text()
        todos = re.findall(r'^\s*- (TODO|LATER|NOW) (.*)', content, re.MULTILINE)
        
        output = f"# Daily Focus - {date.today()}\n\n"
        if not todos:
            output += "No active tasks found."
        for status, task in todos:
            output += f"- [ ] **{status}**: {task}\n"
        OUTPUT_MD.write_text(output)

    if __name__ == "__main__":
        extract()
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
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # enable flakes
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

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

  sops.secrets.filestore_user_password = { };
  sops.secrets.filestore_password_hash = { };
  sops.secrets.filestore_wifi_ssid = { };
  sops.secrets.filestore_wifi_env = {
    owner = "wpa_supplicant";
  };
  sops.secrets.filestore_container_env = { };

  documentation.enable = false;
  documentation.man.enable = false;
  documentation.nixos.enable = false;

  host.homeManagerHostname = "filestore";

  # Stylix Configuration (Headless/Minimal)
  stylix =
    let
      theme = import ../../common/stylix-values.nix { inherit pkgs; };
    in
    {
      enable = true;
      base16Scheme = theme.base16Scheme;
      polarity = theme.polarity;
      fonts = theme.fonts;

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
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
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
      networks."***REMOVED***".psk = "***REMOVED***";
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

  virtualisation.oci-containers.containers = {
    # Nextcloud App
    nextcloud-app = {
      image = "docker.io/library/nextcloud:latest";
      ports = [ "8082:80" ]; # Maps container port 80 to host port 8082
      volumes = [
        "/nextcloud/html:/var/www/html"
        "/nextcloud/data:/var/www/html/data"
        "/nextcloud/config:/var/www/html/config"
      ];
      environment = {
        POSTGRES_HOST = "nextcloud-db";
        POSTGRES_DB = "nextcloud";
        POSTGRES_USER = "nextcloud";
        NEXTCLOUD_ADMIN_USER = "salhashemi2";
        NEXTCLOUD_TRUSTED_DOMAINS = "cloud.salh.xyz";
        OVERWRITEPROTOCOL = "https";
        OVERWRITEHOST = "cloud.salh.xyz";
        TRUSTED_PROXIES = "127.0.0.1 10.88.0.1";
      };
      environmentFiles = [ config.sops.secrets.filestore_container_env.path ];
      extraOptions = [ "--network=nextcloud-net" ];
    };

    # Nextcloud Dedicated Database
    nextcloud-db = {
      image = "docker.io/library/postgres:16-alpine";
      environment = {
        POSTGRES_DB = "nextcloud";
        POSTGRES_USER = "nextcloud";
      };
      environmentFiles = [ config.sops.secrets.filestore_container_env.path ];
      volumes = [ "/nextcloud/db:/var/lib/postgresql/data" ];
      extraOptions = [ "--network=nextcloud-net" ];
    };
  };

  virtualisation.oci-containers.containers.homeassistant = {
    image = "ghcr.io/home-assistant/home-assistant:stable";
    volumes = [
      "/homeassistant:/config"
      "/etc/localtime:/etc/localtime:ro"
    ];
    environment = {
      TZ = "America/New_York"; # Set your timezone
    };
    ports = [ "8123:8123" ];
    extraOptions = [
      "--network=hass-net"
    ];
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
    # Allow outgoing SSH to GitHub
    iptables -t filter -I OUTPUT 1 -p tcp --dport 22 -d 140.82.112.0/20 -j ACCEPT
    # Block all other outgoing SSH to prevent lateral movement
    iptables -t filter -I OUTPUT 2 -p tcp --dport 22 -j REJECT
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

    # Database Folder (UID 999 is postgres inside the container)
    # 'd' creates it if missing; 'z' ensures the 999:999 ownership recursively
    "d /nextcloud/db 0700 999 999 - -"
    "z /nextcloud/db 0700 999 999 - -"

    "d /homeassistant 0755 salhashemi2 users - -"

    # Purge files in /tmp older than 1 day
    "q /tmp 1777 root root 1d -"
  ];

  environment.systemPackages = with pkgs; [
    nmap
    openssl
    logseq-supernote-sync
    health-check
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

  systemd.services.supernote-digest = {
    description = "Generate Daily Task Digest for Supernote";
    path = [ pkgs.git ];
    after = [
      "network.target"
    ];
    serviceConfig = {
      Type = "oneshot";
      User = "salhashemi2";
      # This runs the extraction, installs pysn-digest in a temp venv, and generates the PDF
      ExecStart = pkgs.writeShellScript "run-pysn-digest" ''
        export PATH="${pysnEnv}/bin:$PATH"

        # 1. Run our embedded python extractor
        ${extractTodos}/bin/extract-logseq-todos

        # 2. Clone/Update the repo
        REPO_DIR="/tmp/pysn_digest_repo"
        if [ ! -d "$REPO_DIR" ]; then
             ${pkgs.git}/bin/git clone https://gitlab.com/mmujynya/pysn-digest.git "$REPO_DIR"
        else
             cd "$REPO_DIR" && ${pkgs.git}/bin/git pull
        fi

        # 3. Setup a temporary environment for pysn-digest
        # We rely on nix-provided packages in pysnEnv, but create a venv to allow
        # pip to install any missing minor deps or to satisfy the script's expectations
        # if it tries to self-manage. However, with --system-site-packages we can use nix libs.
        TEMP_VENV="/tmp/pysn_venv"
        if [ ! -d "$TEMP_VENV" ]; then
          python -m venv --system-site-packages "$TEMP_VENV"
          # Install remaining requirements (ignoring those already in system site-packages)
          "$TEMP_VENV/bin/pip" install -r "$REPO_DIR/requirements_pysn.txt"
        fi

        # 4. Generate the PDF onto the SSD
        cd "$REPO_DIR"
        "$TEMP_VENV/bin/python" digest.py \
          --input /tmp/daily_focus.md \
          --output /SupernoteSync/Digests/Daily_Focus.pdf
      '';
    };
  };

  # 5. The Timer (Runs every morning at 8:00 AM)
  systemd.timers.supernote-digest = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 08:00:00";
      Persistent = true; # Run immediately if the Pi was off at 8 AM
    };
  };

  systemd.user.services.logseq-digest = {
    description = "Sync Logseq Daily Journal to Supernote";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${logseq-supernote-sync}/bin/logseq-sync";
    };
    # Ensure the script has the tools it needs in its PATH
    path = [
      pkgs.bash
      pkgs.coreutils
    ];
  };

  systemd.user.timers.logseq-digest = {
    description = "Run Logseq Digest every day at 8 PM";
    timerConfig = {
      OnCalendar = "0/2:00:00";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  # Trading Bot Service (Replaces OpenClaw-based cron)
  systemd.services.coinbase-trader = {
    description = "Run Coinbase Trading Bot";
    path = [ pkgs.nix pkgs.git ]; # Ensure nix and git are in path for flake operations
    serviceConfig = {
      Type = "oneshot";
      User = "salhashemi2";
      ExecStart = "${pkgs.nix}/bin/nix run /home/salhashemi2/trading-bot-flake";
    };
  };

  systemd.timers.coinbase-trader = {
    description = "Run Coinbase Trading Bot every 5 minutes";
    timerConfig = {
      OnCalendar = "*:0/5";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
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
        password = "***REMOVED***";
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
    # Ensure the path is exactly what Postgres expects
    dataDir = "/postgresql/${config.services.postgresql.package.psqlSchema}";
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

  programs.bash.interactiveShellInit = ''
    ${health-check}/bin/sys-health
  '';

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
    preStart = ''
      mkdir -p /forgejo/custom/conf
      chown -R forgejo:forgejo /forgejo
      chmod -R 750 /forgejo
    '';
  };
  programs.dconf.enable = true;
  hardware.enableRedistributableFirmware = true;
  system.stateVersion = "23.11";
}

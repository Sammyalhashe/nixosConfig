{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  user = config.host.username;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules
    inputs.sops-nix.nixosModules.sops
    ./supernote-cloud.nix
    ./supernote-backup.nix
    inputs.terminus.nixosModules.terminus
  ];

  home-manager.users.${config.host.username}.imports = [ ./home.nix ];

  sops.secrets.filestore_container_env = { };
  # Terminus secrets live in the default sops file (secrets.yaml); the container
  # env file is assembled from them via the sops template below.
  sops.secrets.terminus_app_secret = { };
  sops.secrets.terminus_database_password = { };
  sops.secrets.terminus_keyvalue_password = { };
  sops.templates."terminus-env".content = ''
    APP_SECRET=${config.sops.placeholder.terminus_app_secret}
    DATABASE_USER=terminus
    DATABASE_NAME=terminus
    DATABASE_URL=postgres://terminus:${config.sops.placeholder.terminus_database_password}@database:5432/terminus
    KEYVALUE_URL=redis://:${config.sops.placeholder.terminus_keyvalue_password}@keyvalue:6379/0
    POSTGRES_USER=terminus
    POSTGRES_DB=terminus
    POSTGRES_PASSWORD=${config.sops.placeholder.terminus_database_password}
    KEYVALUE_PASSWORD=${config.sops.placeholder.terminus_keyvalue_password}
  '';
  sops.secrets.supernote_email = { };
  sops.secrets.supernote_password = { };
  sops.secrets.supernote_private_key = { };

  host.enableCloudflaredTunnel = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "oldboy"; # Define your hostname.

  host.isHeadless = true;
  host.enableMonitoring = true;
  host.enableCoinbaseSweep = true;

  # Thermal management for lid-closed operation
  services.thermald.enable = true;

  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;
  networking.networkmanager.wifi.scanRandMacAddress = false;

  # Set your time zone.

  # Select internationalisation properties.

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
    openssh.authorizedKeys.keys = [
      config.hostKeys.homebase
      config.hostKeys.mothership
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINUptk+nhbHYTfUJvGT3/X4vkKWRotT5ckw8BiQuADml sammy@salh.xyz"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPx5JBI3FNtugjdVeb1Gg4lUEJvGa/eiZ6rnsIN/oC3f sammy@salh.xyz"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO2hNthWiWeNoxH848/Vhdkc8jWNJw7690ZNAh8RVE9d sammy@salh.xyz"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFZKrkpzxAf0u3+fn59xouUtVHtklRuGwCwfPpR0Y8nc sammy.alhashemi@mail.utoronto.ca"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFvPyYg46ZjVElUNOR6KQOsS56Oytpn4ahgZ1Er7/lke sammy@salh.xyz"
    ];
    linger = true;
  };

  users.users.supernote-sync = {
    isSystemUser = true;
    group = "supernote-sync";
    shell = "${pkgs.shadow}/bin/nologin";
    openssh.authorizedKeys.keys = [
      ''from="11.125.37.98",restrict,port-forwarding,permitopen="127.0.0.1:3306" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOAOdSp9mv8EN7R3EPWPzplz8s37Gs7iY7lznimNR1Vl root@filestore''
    ];
  };
  users.groups.supernote-sync = { };

  # prevent the laptop from hibernating when lid is closed
  services.getty.autologinUser = "${user}";

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    unzip
    python3
  ];
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  # cloudflared runs on this host, so ssh.salh.xyz connections arrive from
  # localhost. No root over the tunnel; LAN deploy-rs (root@11.125.37.175)
  # is unaffected.
  services.openssh.extraConfig = ''
    Match Address 127.0.0.1,::1
      PermitRootLogin no
  '';

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    oci-containers.backend = "podman";
  };

  # Self-hosted TRMNL server (podman OCI stack). LAN-accessible on :2300;
  # exposed remotely via the Cloudflare tunnel. Secrets come from the
  # terminus_env sops secret (secrets-terminus.yaml).
  services.terminus = {
    enable = true;
    apiUri = "http://11.125.37.175:2300";
    environmentFile = config.sops.templates."terminus-env".path;
  };

  systemd.tmpfiles.rules = [
    "d /supernote 0755 salhashemi2 users - -"
    "d /supernote/sndata 0755 salhashemi2 users - -"
  ];

  # oldboy degrades over uptime; reboot weekly rather than relying on manual
  # intervention. Non-persistent: a missed Sunday should not trigger a
  # catch-up reboot at an arbitrary later time.
  systemd.services.scheduled-reboot = {
    description = "Weekly scheduled reboot";
    startAt = "Sun 05:00";
    path = [
      pkgs.procps
      pkgs.coreutils
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      uptime_seconds=$(cut -d. -f1 /proc/uptime)
      if [ "$uptime_seconds" -lt 86400 ]; then
        echo "Uptime under 24h, skipping reboot"
        exit 0
      fi
      if pgrep -f switch-to-configuration >/dev/null; then
        echo "A switch is in progress, skipping reboot"
        exit 0
      fi
      systemctl reboot
    '';
  };

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
    9090 # Prometheus
    19072 # Supernote Web
    19443 # Supernote HTTPS
    18072 # Supernote Sync
  ];

}

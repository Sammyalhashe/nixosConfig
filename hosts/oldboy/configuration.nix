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
    inputs.sops-nix.nixosModules.sops
    ./supernote-cloud.nix
  ];

  sops.secrets.filestore_container_env = { };
  sops.secrets.supernote_email = { };
  sops.secrets.supernote_password = { };
  sops.secrets.supernote_private_key = { };
  sops.secrets.picloud_cloudflare_tunnel_token = {
    owner = "cloudflared";
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 1;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "oldboy"; # Define your hostname.

  host.isHeadless = true;
  host.enableMonitoring = true;

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

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    unzip
    python3
  ];
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    oci-containers.backend = "podman";
  };

  systemd.services.cloudflared-tunnel-picloud = {
    description = "Cloudflare Tunnel (Remote Managed)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      User = "cloudflared";
      Group = "cloudflared";

      ExecStart = pkgs.writeShellScript "start-cloudflared" ''
        TOKEN=$(cat ${config.sops.secrets.picloud_cloudflare_tunnel_token.path})
        exec ${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token "$TOKEN"
      '';

      Restart = "always";
      RestartSec = "5s";

      CapabilityBoundingSet = "";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };

  users.users.cloudflared = {
    group = "cloudflared";
    isSystemUser = true;
  };
  users.groups.cloudflared = { };

  systemd.tmpfiles.rules = [
    "d /supernote 0755 salhashemi2 users - -"
    "d /supernote/sndata 0755 salhashemi2 users - -"
    "d /supernote/sndata/db_data 0700 70 70 - -"
    "d /supernote/sndata/redis_data 0755 999 999 - -"
    "d /supernote/sndata/logs 0755 33 33 - -"
    "d /supernote/sndata/logs/app 0755 33 33 - -"
    "d /supernote/sndata/logs/cloud 0755 33 33 - -"
    "d /supernote/sndata/logs/web 0755 33 33 - -"
    "d /supernote/sndata/convert 0755 salhashemi2 users - -"
    "d /supernote/sndata/recycle 0755 salhashemi2 users - -"
    "d /supernote/sndata/cert 0755 salhashemi2 users - -"
    "d /supernote/supernote_data 0755 salhashemi2 users - -"
  ];

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

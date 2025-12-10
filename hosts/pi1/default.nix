{ pkgs, inputs, config, ... }:

{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    # ../../common/pi-sd-card.nix
  ];

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets.wg_easy_env = { }; # Contains PASSWORD=...
  };

  boot.loader.generic-extlinux-compatible.enable = true;

  # Kernel modules and settings for WireGuard/Container
  boot.kernelModules = [ "wireguard" ];
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking.hostName = "pi1";

  # Open Firewall ports
  networking.firewall.allowedTCPPorts = [ 53 3000 51821 ]; # DNS, AdGuard UI, Wg-Easy UI
  networking.firewall.allowedUDPPorts = [ 53 51820 ];      # DNS, WireGuard

  # AdGuard Home
  services.adguardhome = {
    enable = true;
    port = 3000;
  };

  # Disable systemd-resolved to avoid port 53 conflicts
  services.resolved.enable = false;
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  # Container Engine (Podman)
  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";

  # Wg-Easy Container
  virtualisation.oci-containers.containers.wg-easy = {
    image = "ghcr.io/wg-easy/wg-easy";
    imageFile = null; # Pull from registry
    environment = {
      WG_HOST = "11.125.37.99"; # Public IP of the Pi
      WG_DEFAULT_ADDRESS = "10.100.0.x";
      WG_DEFAULT_DNS = "11.125.37.99"; # Use Pi's AdGuard for DNS
      WG_AllowedIPs = "0.0.0.0/0, ::/0";
      # PASSWORD is provided via environmentFile from SOPS
    };
    environmentFiles = [
      config.sops.secrets.wg_easy_env.path
    ];
    volumes = [
      "/var/lib/wg-easy:/etc/wireguard"
    ];
    ports = [
      "51820:51820/udp"
      "51821:51821/tcp"
    ];
    extraOptions = [
      "--cap-add=NET_ADMIN"
      "--cap-add=SYS_MODULE"
      "--sysctl=net.ipv4.ip_forward=1"
      "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
    ];
  };

  environment.systemPackages = with pkgs; [
    neovim
    nushell
  ];

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    # "ssh-ed25519 ..."
  ];

  system.stateVersion = "24.11";
}

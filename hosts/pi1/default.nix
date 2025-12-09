{ pkgs, inputs, config, ... }:

{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets.wireguard_private_key = { };
  };

  boot.loader.generic-extlinux-compatible.enable = true;

  networking.hostName = "pi1";
  networking.firewall.allowedTCPPorts = [ 53 3000 ];
  networking.firewall.allowedUDPPorts = [ 53 51820 ];

  # Enable NAT for WireGuard
  networking.nat = {
    enable = true;
    externalInterface = "eth0";
    internalInterfaces = [ "wg0" ];
  };

  # WireGuard Server
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.100.0.1/24" ];
      listenPort = 51820;

      # Use `wg genkey` to generate a private key
      # privateKey = "INSERT_PRIVATE_KEY_HERE";
      privateKeyFile = config.sops.secrets.wireguard_private_key.path;

      peers = [
        # Example Peer
        {
          publicKey = "INSERT_CLIENT_PUBLIC_KEY_HERE";
          allowedIPs = [ "10.100.0.2/32" ];
        }
      ];
    };
  };

  services.adguardhome = {
    enable = true;
    port = 3000;
    # By default, AdGuard Home will try to bind to port 53 for DNS.
    # Ensure no other service (like systemd-resolved) is using it.
  };

  # Disable systemd-resolved to avoid port 53 conflicts with AdGuard Home
  services.resolved.enable = false;
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  environment.systemPackages = with pkgs; [
    neovim
    nushell
  ];

  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    # "ssh-ed25519 ..." # Add your SSH public key here to allow Colmena deployment
  ];

  system.stateVersion = "24.11";
}

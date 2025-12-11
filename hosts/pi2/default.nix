{ pkgs, inputs, config, ... }:

{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    inputs.nixos-raspberrypi.nixosModules.raspberry-pi-4.base
    # ../../common/pi-sd-card.nix
  ];

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets.nextcloud_admin_pass = {
      owner = "nextcloud";
    };
  };

  # boot.loader.generic-extlinux-compatible.enable = true; # Managed by nixos-raspberrypi

  networking.hostName = "pi2";

  # Mount external SSD
  fileSystems."/mnt/ssd" = {
    device = "/dev/disk/by-label/SSD";
    fsType = "ext4";
    options = [ "defaults" "nofail" ];
  };

  networking.firewall.allowedTCPPorts = [ 80 443 3000 8384 22000 ];
  networking.firewall.allowedUDPPorts = [ 22000 ];

  users.users.sammy = {
    isNormalUser = true;
    description = "Sammy";
    extraGroups = [ "wheel" ];
  };

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    # "ssh-ed25519 ..." # Add your SSH public key here
  ];

  # Gitea
  services.gitea = {
    enable = true;
    stateDir = "/mnt/ssd/gitea";
    settings.server.HTTP_PORT = 3000;
  };

  # Syncthing
  services.syncthing = {
    enable = true;
    user = "sammy";
    dataDir = "/mnt/ssd/syncthing";
    configDir = "/home/sammy/.config/syncthing";
    guiAddress = "0.0.0.0:8384";
  };

  # Nextcloud
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud29;
    hostName = "nextcloud.local"; # Adjust as needed
    datadir = "/mnt/ssd/nextcloud";
    database.createLocally = true;
    config.dbtype = "pgsql";

    # Initial Admin Setup
    config.adminuser = "admin";
    config.adminpassFile = config.sops.secrets.nextcloud_admin_pass.path;
  };

  environment.systemPackages = with pkgs; [
    neovim
    nushell
  ];

  system.stateVersion = "24.11";
}

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

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
    ./bluetooth.nix
    inputs.home-manager.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
    ../../common/home-manager-config.nix
  ];

  host.enableGreetd = true;
  host.enableBreezy = true;
  host.homeManagerHostname = "default";
  host.fallbackNameservers = [ "11.125.37.1" ];

  # auto upgrade
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 1;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking.hostName = "starship"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = "caps:swapescape";
  };

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.${user} = {
    isNormalUser = true;
    description = "Sammy Al Hashemi";
    extraGroups = [
      "networkmanager"
      "docker"
      "wheel"
      "video"
      "input"
    ];
    packages = with pkgs; [ ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPx5JBI3FNtugjdVeb1Gg4lUEJvGa/eiZ6rnsIN/oC3f sammy@salh.xyz"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFZKrkpzxAf0u3+fn59xouUtVHtklRuGwCwfPpR0Y8nc sammy.alhashemi@mail.utoronto.ca"
    ];
  };

  services.ollama = {
    package = pkgs.ollama-cuda;
    enable = true;
    host = "0.0.0.0";
    loadModels = [
      "qwen2.5-coder:7b"
      "llama3.1:8b"
      "deepseek-r1:7b"
      "qwen2.5:7b"
      "MFDoom/deepseek-r1-tool-calling:8b"
    ];
  };

  services.open-webui = {
    enable = true;
  };

  programs.mango.enable = true;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    (vivaldi.overrideAttrs (oldAttrs: {
      dontWrapQtApps = false;
      dontPatchELF = true;
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pkgs.kdePackages.wrapQtAppsHook ];
    }))
  ];

  # xdg env variables
  environment.sessionVariables = {
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/var/lib";
    XDG_CACHE_HOME = "$HOME/var/cache";
  };

  fonts.packages = with pkgs; [
    monoid
    source-code-pro
  ];

  fonts.fontDir.enable = true;

  services.openssh.enable = true;
  services.flatpak.enable = true;
  services.flatpak.packages = [
    "com.thincast.client"
  ];
  services.flatpak.remotes = [
    {
      name = "flathub";
      location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    }
  ];
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  services.openssh.settings.X11Forwarding = true;

  services.udev.packages = with pkgs; [
    platformio-core.udev
    openocd
  ];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 11434 ];
  };

  security.pki.certificateFiles = [
    (builtins.toFile "wildcard.picloud.crt" (builtins.readFile ../../certs/wildcard.picloud.crt))
    (builtins.toFile "wildcard.rpi.cripz.crt" (builtins.readFile ../../certs/wildcard.rpi.cripz.crt))
  ];

  system.stateVersion = "24.11";
}

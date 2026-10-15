{ config, pkgs, ... }:
{
  sops.secrets.cachix_token = { };
  sops.templates."cachix-env" = {
    content = "CACHIX_AUTH_TOKEN=${config.sops.placeholder.cachix_token}";
    owner = config.host.username;
  };

  # Manual-invocation wrapper (`push-to-cachix [host] [--remote]`); the
  # systemd service below is the automated path.
  environment.systemPackages = [
    (pkgs.stdenv.mkDerivation {
      name = "push-to-cachix";
      dontUnpack = true;
      buildInputs = [
        pkgs.nushell
        pkgs.sops
        pkgs.cachix
      ];
      installPhase = ''
        install -Dm755 ${../../push-to-cachix.nu} $out/bin/push-to-cachix
      '';
    })
  ];

  systemd.services.push-to-cachix = {
    description = "Push NixOS configurations to Cachix";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = config.host.username;
      EnvironmentFile = config.sops.templates."cachix-env".path;
      StateDirectory = "push-to-cachix";
      ExecStart = "${pkgs.nushell}/bin/nu ${../../push-to-cachix.nu} --remote";
    };
    path = [
      pkgs.nix
      pkgs.git
      pkgs.openssh
      pkgs.cachix
      pkgs.nushell
    ];
  };

  systemd.timers.push-to-cachix = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 03:00";
      Persistent = true;
    };
  };
}

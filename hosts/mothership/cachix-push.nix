{ config, pkgs, ... }:
let
  pushToCachix = pkgs.writeShellApplication {
    name = "push-to-cachix";
    runtimeInputs = [
      pkgs.nix
      pkgs.git
      pkgs.openssh
      pkgs.cachix
      pkgs.nushell
      pkgs.sops
    ];
    text = ''
      exec ${pkgs.nushell}/bin/nu ${../../push-to-cachix.nu} "$@"
    '';
  };

  mkService = retry: {
    description = "Build NixOS configurations, push them to Cachix, and advance deployed";
    onFailure = [ "ntfy-deploy-failed@%n.service" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = config.host.username;
      EnvironmentFile = config.sops.templates."cachix-env".path;
      StateDirectory = "push-to-cachix";
      ExecStart = "${pkgs.util-linux}/bin/flock %S/push-to-cachix/run.lock ${pushToCachix}/bin/push-to-cachix --remote${
        if retry then " --retry" else ""
      }";
    };
    path = [
      pkgs.nix
      pkgs.git
      pkgs.openssh
      pkgs.cachix
      pkgs.nushell
      pkgs.util-linux
    ];
  };
in
{
  sops.secrets.cachix_token = { };
  sops.templates."cachix-env" = {
    content = "CACHIX_AUTH_TOKEN=${config.sops.placeholder.cachix_token}";
    owner = config.host.username;
  };

  environment.systemPackages = [ pushToCachix ];

  systemd.services = {
    push-to-cachix = mkService false;
    push-to-cachix-retry = mkService true;

    "ntfy-deploy-failed@" = {
      description = "Report a failed %i run to ntfy";
      serviceConfig.Type = "oneshot";
      scriptArgs = "%i";
      path = [ config.host.ntfy.publish ];
      script = ''
        journalctl -u "$1" --since -3h --no-pager -o cat \
          | grep -E "failed|Not advancing" | tail -n 25 | tail -c 3500 \
          | ntfy-publish deploys "Deploy pipeline failed ($1)" rotating_light high
      '';
    };
  };

  systemd.timers = {
    push-to-cachix = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/15";
        Persistent = true;
      };
    };
    push-to-cachix-retry = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "03:00";
        Persistent = true;
      };
    };
  };
}

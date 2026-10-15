{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.host.enableCloudflaredTunnel {
  sops.secrets.picloud_cloudflare_tunnel_token = {
    owner = "cloudflared";
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
}

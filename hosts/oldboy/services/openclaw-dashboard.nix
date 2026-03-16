{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.openclaw-dashboard;
  user = config.users.users.${config.host.username};
in
{
  options.services.openclaw-dashboard = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable the OpenClaw Debug Dashboard.";
    };

    port = mkOption {
      type = types.int;
      default = 6969;
      description = "Port to expose the dashboard on.";
    };

    apiUrl = mkOption {
      type = types.str;
      default = "http://localhost:3000";
      description = "API URL for the dashboard to connect to.";
    };

    env = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Additional environment variables for the dashboard.";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    systemd.user.services.openclaw-dashboard = {
      description = "OpenClaw Debug Dashboard (Podman)";
      after = [ "network.target" ];
      requires = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.podman}/bin/podman compose up";
        ExecReload = "${pkgs.podman}/bin/podman compose up --build";
        Restart = "on-failure";
        RestartSec = 5;

        Environment = [
          "PORT=${toString cfg.port}"
          "API_URL=${cfg.apiUrl}"
        ]
        ++ map (name: "${name}=${cfg.env.${name}}") (attrNames cfg.env);

        StandardOutput = "journal";
        StandardError = "journal";
      };

      wantedBy = [ "default.target" ];
      path = [ pkgs.podman ];
    };
  };
}

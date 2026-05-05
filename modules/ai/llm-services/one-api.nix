{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.llm-services.one-api;
  one-api-pkg = pkgs.stdenv.mkDerivation {
    name = "one-api";
    src = pkgs.fetchurl {
      url = "https://github.com/songquanpeng/one-api/releases/download/v0.6.10/one-api";
      sha256 = "066an86pyg9lq9byhd0in02nla25r6i64860x7gz3v02jmygz4g8";
    };
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/one-api
      chmod +x $out/bin/one-api
    '';
  };
in
{
  options.services.llm-services.one-api = {
    enable = mkEnableOption "One-API Proxy Service (Port 3000)";
    port = mkOption {
      type = types.port;
      default = 3001;
      description = "Port for One-API to listen on.";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/one-api";
      description = "Directory to store One-API data (SQLite database, etc).";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.one-api = {
      description = "One-API Proxy Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        PORT = toString cfg.port;
        DATA_DIR = cfg.dataDir;
        SQLITE_PATH = "${cfg.dataDir}/one-api.db";
        SESSION_SECRET = "change_me_later"; # Should ideally be a secret
      };

      serviceConfig = {
        User = "salhashemi2";
        Group = "users";
        StateDirectory = "one-api";
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${one-api-pkg}/bin/one-api";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}

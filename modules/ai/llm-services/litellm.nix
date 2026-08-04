{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.llm-services.litellm;
in
{
  options.services.llm-services.litellm = {
    enable = mkEnableOption "LiteLLM Proxy Service (Port 4000)";
    configPath = mkOption {
      type = types.str;
      default = "/home/salhashemi2/nixosConfig/litellm-config.yaml";
      description = "Path to the litellm-config.yaml file.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.litellm = {
      description = "LiteLLM Proxy Server (Master Router)";
      after = [
        "network.target"
        "llama-cpp-flash.service"
        "llama-cpp-coder.service"
      ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        PORT = "4000";
        HOST = "0.0.0.0";
      };
      serviceConfig = {
        User = "salhashemi2";
        Group = "users";
        ExecStart =
          let
            # Use litellm's own `proxy` optional-dependencies from nixpkgs
            # (equivalent to the PyPI `litellm[proxy]` extra) rather than a
            # hand-maintained package list — reproducible and always in sync
            # with the packaged litellm version.
            pythonEnv = pkgs.python313.withPackages (
              ps: [ ps.litellm ] ++ ps.litellm.optional-dependencies.proxy
            );
          in
          "${pythonEnv}/bin/litellm --config ${cfg.configPath} --port 4000 --host 0.0.0.0";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}

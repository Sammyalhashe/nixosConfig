{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.llm-services.litellm-uv;
in
{
  options.services.llm-services.litellm-uv = {
    enable = mkEnableOption "LiteLLM Proxy Service via UV (Port 4000)";
    configPath = mkOption {
      type = types.str;
      default = "/home/salhashemi2/nixosConfig/litellm-config.yaml";
      description = "Path to the litellm-config.yaml file.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.litellm = {
      description = "LiteLLM Proxy Server (Master Router via UV)";
      after = [
        "network.target"
        "llama-cpp-flash.service"
        "llama-cpp-coder.service"
      ];
      wantedBy = [ "multi-user.target" ];

      path = [
        pkgs.uv
        pkgs.python3
        pkgs.bash
        pkgs.coreutils
      ];

      serviceConfig = {
        User = "salhashemi2";
        Group = "users";
        # Use UV to run litellm with proxy dependencies.
        # Note: Escaping double quotes for bash.
        ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.uv}/bin/uv tool run --with \"litellm[proxy]\" litellm --config ${cfg.configPath} --port 4000 --host 0.0.0.0'";
        Restart = "on-failure";
        RestartSec = "5s";
        # Required for uv to store its tools and for binaries to find libraries
        Environment = [
          "HOME=/home/salhashemi2"
          "LD_LIBRARY_PATH=${
            lib.makeLibraryPath [
              pkgs.stdenv.cc.cc
              pkgs.zlib
            ]
          }"
        ];
      };
    };
  };
}

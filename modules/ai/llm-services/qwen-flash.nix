{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.llm-services.qwen-flash;
in
{
  options.services.llm-services.qwen-flash = {
    enable = mkEnableOption "Qwen2.5-7B Flash Service (Port 8011)";
    modelPath = mkOption {
      type = types.str;
      default = "/var/lib/llama-cpp-models/qwen2.5-7b-instruct-q8_0.gguf";
      description = "Path to the Qwen Flash GGUF model.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.llama-cpp-flash = {
      description = "LLaMA C++ server (Qwen Flash - Port 8011)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        XDG_CACHE_HOME = "/var/cache/llama-cpp-flash";
      }
      // config.services.llm-services.backend.environment;

      serviceConfig = {
        User = "salhashemi2";
        Group = "users";
        DeviceAllow = [
          "/dev/dri/renderD128"
          "/dev/dri/card0"
          "/dev/kfd"
        ];
        PrivateDevices = false;

        ExecStart =
          # llama.cpp build (ROCm or Vulkan) is selected by
          # services.llm-services.backend — see ./backend.
          "${config.services.llm-services.backend.package}/bin/llama-server "
          + "--model ${cfg.modelPath} "
          + "--port 8011 "
          + "--host 0.0.0.0 "
          + "--n-gpu-layers 999 "
          + "--ctx-size 32768 "
          + "--parallel 1 "
          + "--threads 8 "
          + "--flash-attn 1 "
          + "--no-mmap";

        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}

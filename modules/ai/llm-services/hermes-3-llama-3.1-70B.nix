{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.llm-services.llama-cpp-hermes;
in
{
  options.services.llm-services.llama-cpp-hermes = {
    enable = mkEnableOption "hermes-3-llama-3.1 Service (Port 8014)";
    modelPath = mkOption {
      type = types.str;
      default = "/var/lib/llama-cpp-models/Hermes-3-Llama-3.1-70B-Q5_K_M-00001-of-00002.gguf";
      description = "Path to the hermes-3-llama-3.1 GGUF model.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.llama-cpp-hermes = {
      description = "LLaMA C++ server (hermes-3-llama-3 - Port 8014)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        XDG_CACHE_HOME = "/var/cache/llama-cpp-hermes";
        AMD_VULKAN_ICD = "RADV";
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
          + "--port 8014 "
          + "--host 0.0.0.0 "
          + "--n-gpu-layers 999 "
          + "--ctx-size 131072 "
          + "--cache-type-k q8_0 " # Prevents ~43GB KV cache allocation at 128k context
          + "--cache-type-v q8_0 "
          + "--batch-size 4096 " # Accelerates prefill phase when Hermes loads huge contexts
          + "--ubatch-size 512 "
          + "--parallel 1 "
          + "--threads 8 " # Reduced from 16 to eliminate CPU/GPU bus contention
          + "--flash-attn 1 "
          + "--temp 0.6 "
          + "--top-p 0.95 "
          + "--top-k 20 "
          + "--min-p 0.05 " # Re-enabled (was 0.00); critical for Hermes tool-use stability
          + "--no-mmap"; # MANDATORY for Strix Halo to prevent paging stalls

        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}

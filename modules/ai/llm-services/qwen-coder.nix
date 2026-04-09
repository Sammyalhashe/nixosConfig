{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.llm-services.qwen-coder;
in
{
  options.services.llm-services.qwen-coder = {
    enable = mkEnableOption "Qwen3-Coder-Next Service (Port 8014)";
    modelPath = mkOption {
      type = types.str;
      default = "/var/lib/llama-cpp-models/qwen3_next_q4km.gguf";
      description = "Path to the Qwen3-Coder-Next GGUF model.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.llama-cpp-coder = {
      description = "LLaMA C++ server (Qwen3-Coder-Next - Port 8014)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        XDG_CACHE_HOME = "/var/cache/llama-cpp-coder";
        HSA_OVERRIDE_GFX_VERSION = "11.5.1";
        HSA_ENABLE_SDMA = "0";
      };

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
          let
            # --- STABLE AI STACK ---
            # Qwen3 uses the optimized ROCm stack provided by the OpenClaw overlay.
            # This is pinned to a 'known-good' revision for heavy development work.
            llama-rocm = pkgs.pkgsRocm.llama-cpp;
          in
          "${llama-rocm}/bin/llama-server "
          + "--model ${cfg.modelPath} "
          + "--port 8014 "
          + "--host 0.0.0.0 "
          + "--n-gpu-layers 999 "
          + "--ctx-size 131072 "
          + "--parallel 1 "
          + "--threads 16 "
          + "--flash-attn 1 "
          + "--no-mmap";         # MANDATORY for Strix Halo to prevent paging stalls
        
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.llm-services.gemma;
  top = config.services.llm-services;

  modelArgs =
    if cfg.hfRepo != null then
      "--hf-repo ${cfg.hfRepo} --hf-file ${cfg.hfFile} "
    else
      "--model ${cfg.modelPath} ";
in
{
  options.services.llm-services.gemma = {
    enable = mkEnableOption "Gemma 4 Service (Port 8012)";
    hfRepo = mkOption {
      type = types.nullOr types.str;
      default = "bartowski/google_gemma-4-31B-it-GGUF";
      description = ''
        HuggingFace repo passed to llama-server --hf-repo. Set to null to load a
        local file from modelPath instead.
      '';
    };
    hfFile = mkOption {
      type = types.str;
      default = "google_gemma-4-31B-it-Q4_K_M.gguf";
      description = "GGUF within hfRepo. Ignored when hfRepo is null.";
    };
    modelPath = mkOption {
      type = types.str;
      default = "${top.modelCacheDir}/google_gemma-4-31B-it-Q4_K_M.gguf";
      description = "Local GGUF path, used only when hfRepo is null.";
    };
    draftModelPath = mkOption {
      type = types.str;
      default = "${top.modelCacheDir}/qwen2.5-1.5b-instruct-q8_0.gguf";
      description = ''
        Draft model for speculative decoding. Local path: llama-server's --hf-*
        flags cover the main model only.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.llama-cpp-gemma = {
      description = "LLM Gemma 4 Server (ROCm - Strix Halo)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        XDG_CACHE_HOME = "/var/cache/llama-cpp-gemma";
        LLAMA_CACHE = top.modelCacheDir;
      }
      # The HSA_* overrides were pinned here unconditionally; they are ROCm-only
      # and the backend module now supplies them.
      // config.services.llm-services.backend.environment;

      serviceConfig = {
        User = "salhashemi2";
        Group = "users";
        StateDirectory = "llama-cpp-models";
        CacheDirectory = "llama-cpp-gemma";
        DeviceAllow = [
          "/dev/dri/renderD128"
          "/dev/dri/card0"
          "/dev/kfd"
        ];
        PrivateDevices = false;

        ExecStart =
          # Was a private useRocm override, which pinned this service to ROCm
          # regardless of the selected backend. The backend's own ROCm build
          # already carries NO_VMM (see its system_info line).
          "${config.services.llm-services.backend.package}/bin/llama-server "
          + modelArgs
          + "--model-draft ${cfg.draftModelPath} "
          + "--draft 5 "
          + "--threads-draft 4 "
          + "--port 8012 "
          + "--host 0.0.0.0 "
          + "--n-gpu-layers 999 " # Force full GPU offload (Strix Halo has 128GB Unified Memory)
          + "--ctx-size 65536 " # Reduced context for "usable" daily speed
          + "--parallel 1 "
          + "--threads 12 " # Headroom for GPU command processor
          + "--flash-attn 1 "
          + "--load-mode none"; # Crucial for Unified Memory to prevent paging stalls and kernel freezes

        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}

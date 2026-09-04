{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.llm-services.llama-cpp-hermes;
  top = config.services.llm-services;

  # Prefer letting llama-server fetch the model itself: it reads split.count
  # from the first shard and pulls the remaining ones, so a split GGUF can never
  # end up half-present under the wrong name.
  modelArgs =
    if cfg.hfRepo != null then
      "--hf-repo ${cfg.hfRepo} --hf-file ${cfg.hfFile} "
    else
      "--model ${cfg.modelPath} ";
in
{
  options.services.llm-services.llama-cpp-hermes = {
    enable = mkEnableOption "hermes-3-llama-3.1 Service (Port 8014)";
    hfRepo = mkOption {
      type = types.nullOr types.str;
      default = "bartowski/Hermes-3-Llama-3.1-70B-GGUF";
      description = ''
        HuggingFace repo passed to llama-server --hf-repo. Set to null to load a
        local file from modelPath instead.
      '';
    };
    hfFile = mkOption {
      type = types.str;
      default = "Hermes-3-Llama-3.1-70B-Q5_K_M/Hermes-3-Llama-3.1-70B-Q5_K_M-00001-of-00002.gguf";
      description = ''
        First shard of the Q5_K_M split GGUF within hfRepo (39.9 GB + 10.1 GB).
        bartowski keeps split quants in a per-quant subfolder. Ignored when
        hfRepo is null.
      '';
    };
    modelPath = mkOption {
      type = types.str;
      default = "${top.modelCacheDir}/Hermes-3-Llama-3.1-70B-Q5_K_M-00001-of-00002.gguf";
      description = "Local GGUF path, used only when hfRepo is null.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.llama-cpp-hermes = {
      description = "LLaMA C++ server (hermes-3-llama-3 - Port 8014)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        XDG_CACHE_HOME = "/var/cache/llama-cpp-hermes";
        LLAMA_CACHE = top.modelCacheDir;
      }
      # AMD_VULKAN_ICD is set by the Vulkan backend for every service now.
      // config.services.llm-services.backend.environment;

      serviceConfig = {
        User = "salhashemi2";
        Group = "users";
        # Creates ${top.modelCacheDir} and chowns it to User, so llama-server
        # can write the models it downloads.
        StateDirectory = "llama-cpp-models";
        # XDG_CACHE_HOME above points here. Without this systemd never creates
        # it, and the RADV shader cache is silently disabled at every start.
        CacheDirectory = "llama-cpp-hermes";
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
          + modelArgs
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
          + "--load-mode none"; # MANDATORY for Strix Halo to prevent paging stalls

        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}

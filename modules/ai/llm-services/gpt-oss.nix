{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.llm-services.gpt-oss;
  top = config.services.llm-services;

  modelArgs =
    if cfg.hfRepo != null then
      "--hf-repo ${cfg.hfRepo} --hf-file ${cfg.hfFile} "
    else
      "--model ${cfg.modelPath} ";
in
{
  options.services.llm-services.gpt-oss = {
    enable = mkEnableOption "GPT-OSS 120B Service (Port 8013)";
    hfRepo = mkOption {
      type = types.nullOr types.str;
      default = "bartowski/openai_gpt-oss-120b-GGUF";
      description = ''
        HuggingFace repo passed to llama-server --hf-repo. Set to null to load a
        local file from modelPath instead.
      '';
    };
    hfFile = mkOption {
      type = types.str;
      default = "openai_gpt-oss-120b-IQ4_XS/openai_gpt-oss-120b-IQ4_XS-00001-of-00002.gguf";
      description = ''
        First shard of the IQ4_XS split GGUF within hfRepo. Like Hermes, this
        quant lives in a per-quant subfolder. Ignored when hfRepo is null.
      '';
    };
    modelPath = mkOption {
      type = types.str;
      default = "${top.modelCacheDir}/openai_gpt-oss-120b-IQ4_XS-00001-of-00002.gguf";
      description = "Local GGUF path, used only when hfRepo is null.";
    };
    draftModelPath = mkOption {
      type = types.nullOr types.str;
      default = "${top.modelCacheDir}/qwen2.5-1.5b-instruct-q8_0.gguf";
      description = ''
        Path to the draft model for speculative decoding. Still a local path:
        llama-server's --hf-* flags cover the main model only, so this file has
        to be fetched separately (Qwen/Qwen2.5-1.5B-Instruct-GGUF,
        qwen2.5-1.5b-instruct-q8_0.gguf).
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.llama-cpp-reasoning = {
      description = "LLaMA C++ server (Master - GPT-OSS 120B)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        XDG_CACHE_HOME = "/var/cache/llama-cpp-reasoning";
        LLAMA_CACHE = top.modelCacheDir;
        # Inject Lemonade Runtime Libs (as per working config)
        LD_LIBRARY_PATH = lib.makeLibraryPath [
          pkgs.rocmPackages.clr
          pkgs.vulkan-loader
          pkgs.libdrm
        ];
      }
      # RADV_PERFTEST / AMD_VULKAN_ICD used to be pinned here even under ROCm;
      # the backend module owns them now.
      // config.services.llm-services.backend.environment;
      serviceConfig = {
        User = "salhashemi2";
        Group = "users";
        StateDirectory = "llama-cpp-models";
        CacheDirectory = "llama-cpp-reasoning";
        RuntimeDirectory = "llama-cpp-reasoning";
        DeviceAllow = [
          "/dev/dri/renderD128"
          "/dev/dri/card0"
          "/dev/kfd"
        ];
        PrivateDevices = false;
        ExecStart =
          let
            draftFlags =
              if cfg.draftModelPath != null then
                "--model-draft ${cfg.draftModelPath} --n-gpu-layers-draft 1000 --ctx-size-draft 8192 --draft 5"
              else
                "";
          in
          # Was hardcoded to its own vulkanSupport build with --device Vulkan0,
          # which silently ignored the selected backend and broke under ROCm.
          "${config.services.llm-services.backend.package}/bin/llama-server "
          + modelArgs
          + "${draftFlags} --port 8013 --host 0.0.0.0 --n-gpu-layers 1000 --cache-type-k q8_0 --cache-type-v q8_0 --ctx-size 131072 --threads 16 --flash-attn 1 --load-mode none --parallel 1";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}

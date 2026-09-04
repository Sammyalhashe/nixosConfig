{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.llm-services.qwen-coder;
  top = config.services.llm-services;

  modelArgs =
    if cfg.hfRepo != null then
      "--hf-repo ${cfg.hfRepo} --hf-file ${cfg.hfFile} "
    else
      "--model ${cfg.modelPath} ";
in
{
  options.services.llm-services.qwen-coder = {
    # NOTE: port 8014 collides with llama-cpp-hermes. Only one of the two may be
    # enabled at a time until one of them is moved.
    enable = mkEnableOption "Qwen3-Coder-Next Service (Port 8014)";
    hfRepo = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        HuggingFace repo passed to llama-server --hf-repo. Left null because no
        published repo for Qwen3.6-35B-A3B-MXFP4_MOE could be confirmed, so this
        service still loads the local file at modelPath.
      '';
    };
    hfFile = mkOption {
      type = types.str;
      default = "";
      description = "GGUF within hfRepo. Ignored when hfRepo is null.";
    };
    modelPath = mkOption {
      type = types.str;
      default = "${top.modelCacheDir}/Qwen3.6-35B-A3B-MXFP4_MOE.gguf";
      description = "Path to the Qwen3-Coder-Next GGUF model.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.llama-cpp-coder = {
      description = "LLaMA C++ server (Qwen3.6 - Port 8014)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        XDG_CACHE_HOME = "/var/cache/llama-cpp-coder";
        LLAMA_CACHE = top.modelCacheDir;
      }
      // config.services.llm-services.backend.environment;

      serviceConfig = {
        User = "salhashemi2";
        Group = "users";
        StateDirectory = "llama-cpp-models";
        CacheDirectory = "llama-cpp-coder";
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
          + "--parallel 1 "
          + "--threads 16 "
          + "--flash-attn 1 "
          + "--temp 0.6 "
          + "--top-p 0.95 "
          + "--top-k 20 "
          + "--min-p 0.00 "
          + "--load-mode none"; # MANDATORY for Strix Halo to prevent paging stalls

        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}

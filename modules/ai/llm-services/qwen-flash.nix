{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.llm-services.qwen-flash;
  top = config.services.llm-services;

  modelArgs =
    if cfg.hfRepo != null then
      "--hf-repo ${cfg.hfRepo} --hf-file ${cfg.hfFile} "
    else
      "--model ${cfg.modelPath} ";
in
{
  options.services.llm-services.qwen-flash = {
    enable = mkEnableOption "Qwen2.5-7B Flash Service (Port 8011)";
    hfRepo = mkOption {
      type = types.nullOr types.str;
      default = "bartowski/Qwen2.5-7B-Instruct-GGUF";
      description = ''
        HuggingFace repo passed to llama-server --hf-repo. Set to null to load a
        local file from modelPath instead.
      '';
    };
    hfFile = mkOption {
      type = types.str;
      default = "Qwen2.5-7B-Instruct-Q8_0.gguf";
      description = "GGUF within hfRepo. Ignored when hfRepo is null.";
    };
    modelPath = mkOption {
      type = types.str;
      default = "${top.modelCacheDir}/qwen2.5-7b-instruct-q8_0.gguf";
      description = "Local GGUF path, used only when hfRepo is null.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.llama-cpp-flash = {
      description = "LLaMA C++ server (Qwen Flash - Port 8011)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        XDG_CACHE_HOME = "/var/cache/llama-cpp-flash";
        LLAMA_CACHE = top.modelCacheDir;
      }
      // config.services.llm-services.backend.environment;

      serviceConfig = {
        User = "salhashemi2";
        Group = "users";
        StateDirectory = "llama-cpp-models";
        CacheDirectory = "llama-cpp-flash";
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
          + "--port 8011 "
          + "--host 0.0.0.0 "
          + "--n-gpu-layers 999 "
          + "--ctx-size 32768 "
          + "--parallel 1 "
          + "--threads 8 "
          + "--flash-attn 1 "
          + "--load-mode none";

        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}

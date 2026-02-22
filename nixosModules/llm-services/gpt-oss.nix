{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.llm-services.gpt-oss;
in
{
  options.services.llm-services.gpt-oss = {
    enable = mkEnableOption "GPT-OSS Reasoning Service (Port 8013)";
    modelPath = mkOption {
      type = types.str;
      default = "/var/lib/llama-cpp-models/openai_gpt-oss-120b-IQ4_XS-00001-of-00002.gguf";
      description = "Path to the GPT-OSS GGUF model.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.llama-cpp-reasoning = {
      description = "LLaMA C++ server (Reasoning - GPT-OSS)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        XDG_CACHE_HOME = "/var/cache/llama-cpp-reasoning";
        RADV_PERFTEST = "aco";
        AMD_VULKAN_ICD = "RADV";
        # Inject Lemonade Runtime Libs (as per working config)
        LD_LIBRARY_PATH = lib.makeLibraryPath [
          pkgs.rocmPackages.clr
          pkgs.vulkan-loader
          pkgs.libdrm
        ];
      };
      serviceConfig = {
        User = "salhashemi2";
        Group = "users";
        CacheDirectory = "llama-cpp-reasoning";
        RuntimeDirectory = "llama-cpp-reasoning";
        DeviceAllow = [ "/dev/dri/renderD128" "/dev/dri/card0" "/dev/kfd" ];
        PrivateDevices = false;
        ExecStart = "${pkgs.llama-cpp.override { vulkanSupport = true; }}/bin/llama-server --model ${cfg.modelPath} --port 8013 --host 0.0.0.0 --n-gpu-layers 60 --cache-type-k q8_0 --cache-type-v q8_0 --ctx-size 8192 --jinja --threads 16 --device Vulkan0 --flash-attn 1";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}

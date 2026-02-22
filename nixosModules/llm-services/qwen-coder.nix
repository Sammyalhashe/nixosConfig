{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.llm-services.qwen-coder;
in
{
  options.services.llm-services.qwen-coder = {
    enable = mkEnableOption "Qwen3-Coder-Next Service (Port 8012)";
    modelPath = mkOption {
      type = types.str;
      default = "/var/lib/llama-cpp-models/qwen3_next_q3km.gguf";
      description = "Path to the Qwen3-Coder-Next GGUF model.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.llama-cpp-coder = {
      description = "LLaMA C++ server (Qwen3-Coder-Next - Port 8012)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        XDG_CACHE_HOME = "/var/cache/llama-cpp-coder";
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
        CacheDirectory = "llama-cpp-coder";
        RuntimeDirectory = "llama-cpp-coder";
        DeviceAllow = [ "/dev/dri/renderD128" "/dev/dri/card0" "/dev/kfd" ];
        PrivateDevices = false;
        # Using the same Vulkan override as the reasoning service
        # --no-mmap: Crucial for large MoE models on unified memory to prevent thrashing
        ExecStart = "${pkgs.llama-cpp.override { vulkanSupport = true; }}/bin/llama-server --model ${cfg.modelPath} --port 8012 --host 0.0.0.0 --n-gpu-layers 65 --ctx-size 32768 --jinja --threads 16 --device Vulkan0 --flash-attn 1 --no-mmap";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.llm-services.qwen-flash;
in
{
  options.services.llm-services.qwen-flash = {
    enable = mkEnableOption "Qwen2.5-Coder-7B Service (Port 8011)";
    modelPath = mkOption {
      type = types.str;
      default = "/var/lib/llama-cpp-models/qwen2.5-coder-7b-instruct-q8_0.gguf";
      description = "Path to the Qwen2.5-Coder-7B GGUF model.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.llama-cpp-flash = {
      description = "LLaMA C++ server (Qwen2.5-Coder-7B - Port 8011)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        XDG_CACHE_HOME = "/var/cache/llama-cpp-flash";
        RADV_PERFTEST = "aco";
        AMD_VULKAN_ICD = "RADV";
        LD_LIBRARY_PATH = lib.makeLibraryPath [
          pkgs.rocmPackages.clr
          pkgs.vulkan-loader
          pkgs.libdrm
        ];
      };
      serviceConfig = {
        User = "salhashemi2";
        Group = "users";
        CacheDirectory = "llama-cpp-flash";
        RuntimeDirectory = "llama-cpp-flash";
        DeviceAllow = [ "/dev/dri/renderD128" "/dev/dri/card0" "/dev/kfd" ];
        PrivateDevices = false;
        # --n-gpu-layers: 7B models have ~28 layers. Setting to 40 ensures full GPU offload.
        # --ctx-size: 32768 is plenty for "Flash" tasks.
        ExecStart = "${pkgs.llama-cpp.override { vulkanSupport = true; }}/bin/llama-server --model ${cfg.modelPath} --port 8011 --host 0.0.0.0 --n-gpu-layers 40 --ctx-size 32768 --jinja --threads 8 --device Vulkan0 --flash-attn 1";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 1";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}

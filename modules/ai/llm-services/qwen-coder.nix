{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.services.llm-services.qwen-coder;
in
{
  options.services.llm-services.qwen-coder = {
    enable = mkEnableOption "Qwen3-Coder-Next Service (Port 8012)";
    modelPath = mkOption {
      type = types.str;
      # default = "/var/lib/llama-cpp-models/qwen3_next_q4km.gguf";
      default = "/var/lib/llama-cpp-models/gemma-4-31B-it-Q8_0.gguf";
      description = "Path to the Qwen3-Coder-Next GGUF model.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.llama-cpp-coder = {
      description = "Gemma 4 Server (ROCm - Strix Halo)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        XDG_CACHE_HOME = "/var/cache/llama-cpp-coder";
        # Tells ROCm to treat the 8060S as a high-end RDNA 3.5 compute device
        HSA_OVERRIDE_GFX_VERSION = "11.5.1";
        # Optimization for Unified Memory to prevent SDMA overhead
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
            # This now uses the Gemma 4 code from your flake input!
            llama-pkg =
              (pkgs.llama-cpp.override {
                                useRocm = true;
              }).overrideAttrs
                (old: {
                  # CRITICAL STRIX HALO HARDWARE FIXES
                  cmakeFlags = (old.cmakeFlags or [ ]) ++ [
                    "-DGGML_HIP_NO_VMM=ON" # MANDATORY for Strix Halo stability
                    "-DAMDGPU_TARGETS=gfx1151" # Direct target for 8060S
                  ];
                });
          in
          # let
          #   # Ensure we are using the 2026 ROCm 7.2 stack
          #   llama-rocm = pkgs.pkgsRocm.llama-cpp;
          #   # llama-rocm = pkgs.llama-cpp.override {
          #   #   rocmSupport = true;
          #   #   rocmPackages = pkgs.rocmPackages_7_2;
          #   # };
          # in
          "${llama-pkg}/bin/llama-server "
          + "--model ${cfg.modelPath} "
          + "--port 8012 "
          + "--host 0.0.0.0 "
          + "--n-gpu-layers 999 "
          # Force full GPU offload to the 128GB pool
          + "--ctx-size 262144 "
          # Gemma 4's native context window
          + "--parallel 1 "
          + "--threads 16 "
          + "--flash-attn 1 "
          + "--no-mmap"; # Essential for Strix Halo to prevent paging stalls
      };
    };
  };

  # config = mkIf cfg.enable {
  #   systemd.services.llama-cpp-coder = {
  #     description = "LLaMA C++ server (Qwen3-Coder-Next - Port 8012)";
  #     after = [ "network.target" ];
  #     wantedBy = [ "multi-user.target" ];
  #     environment = {
  #       XDG_CACHE_HOME = "/var/cache/llama-cpp-coder";
  #       RADV_PERFTEST = "aco";
  #       AMD_VULKAN_ICD = "RADV";
  #       # Inject Lemonade Runtime Libs (as per working config)
  #       LD_LIBRARY_PATH = lib.makeLibraryPath [
  #         pkgs.rocmPackages.clr
  #         pkgs.vulkan-loader
  #         pkgs.libdrm
  #       ];
  #     };
  #     serviceConfig = {
  #       User = "salhashemi2";
  #       Group = "users";
  #       CacheDirectory = "llama-cpp-coder";
  #       RuntimeDirectory = "llama-cpp-coder";
  #       DeviceAllow = [
  #         "/dev/dri/renderD128"
  #         "/dev/dri/card0"
  #         "/dev/kfd"
  #       ];
  #       PrivateDevices = false;
  #       # Using the same Vulkan override as the reasoning service
  #       # --no-mmap: Crucial for large MoE models on unified memory to prevent thrashing
  #       ExecStart = "${
  #         pkgs.llama-cpp.override { vulkanSupport = true; }
  #       }/bin/llama-server --model ${cfg.modelPath} --port 8012 --host 0.0.0.0 --n-gpu-layers 65 --ctx-size 131072 --parallel 1 --jinja --threads 16 --device Vulkan0 --flash-attn 1 --no-mmap";
  #       ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
  #       Restart = "on-failure";
  #       RestartSec = "5s";
  #     };
  #   };
  # };
}

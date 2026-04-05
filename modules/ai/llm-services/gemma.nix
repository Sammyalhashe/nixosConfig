{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.llm-services.gemma;
in
{
  options.services.llm-services.gemma = {
    enable = mkEnableOption "Gemma 4 Service (Port 8012)";
    modelPath = mkOption {
      type = types.str;
      default = "/var/lib/llama-cpp-models/gemma-4-26B-A4B-it-Q8_0.gguf";
      description = "Path to the model GGUF file.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.llama-cpp-gemma = {
      description = "LLM Gemma 4 Server (ROCm - Strix Halo)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        XDG_CACHE_HOME = "/var/cache/llama-cpp-gemma";
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
            # --- CUSTOM LLAMA.CPP BUILD ---
            # Gemma 4 requires the latest C++ architecture definitions.
            # We override the standard package to ensure it uses the ROCm 7.2 stack
            # and includes mandatory hardware fixes for Strix Halo.
            llama-pkg =
              (pkgs.llama-cpp.override {
                useRocm = true;
              }).overrideAttrs
                (old: {
                  cmakeFlags = (old.cmakeFlags or [ ]) ++ [
                    "-DGGML_HIP_NO_VMM=ON" # MANDATORY for Strix Halo stability (Prevents IOMMU pagefaults)
                    "-DAMDGPU_TARGETS=gfx1151" # Direct target for Strix Halo 8060S (GFX 11.5.1)
                  ];
                });
          in
          "${llama-pkg}/bin/llama-server "
          + "--model ${cfg.modelPath} "
          + "--port 8012 "
          + "--host 0.0.0.0 "
          + "--n-gpu-layers 999 "  # Force full GPU offload (Strix Halo has 128GB Unified Memory)
          + "--ctx-size 262144 "   # Gemma 4's native context window
          + "--parallel 1 "
          + "--threads 16 "
          + "--flash-attn 1 "
          + "--no-mmap";         # Crucial for Unified Memory to prevent paging stalls and kernel freezes
        
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}

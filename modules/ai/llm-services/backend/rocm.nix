{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.llm-services.backend;
in
lib.mkIf cfg.enableRocm {
  services.llm-services.backend = {
    # Preserve the exact ROCm build the host already runs (built against this
    # system's nixpkgs), rather than the llama.cpp flake's own rocm output.
    package = pkgs.pkgsRocm.llama-cpp;

    # ROCm runtime workarounds for Strix Halo (gfx1151).
    environment = {
      HSA_OVERRIDE_GFX_VERSION = "11.5.1";
      HSA_ENABLE_SDMA = "0";
    };
  };

  # ROCm-specific kernel workarounds. Living here (not the host boot config)
  # means selecting the Vulkan backend drops them automatically. Display and
  # unified-memory kernel params stay in the host config since they apply to
  # both backends.
  boot.kernelParams = [
    "amd_iommu=off" # avoid SDMA/VMM pagefaults on Strix Halo under ROCm
    "amdgpu.cwsr_enable=0" # disable compute wave save/restore for ROCm stability
    "amdgpu.runpm=0" # keep the GPU awake for ROCm/KFD device discovery
  ];
}

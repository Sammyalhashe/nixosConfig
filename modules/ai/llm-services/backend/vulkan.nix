{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.services.llm-services.backend;
in
lib.mkIf cfg.enableVulkan {
  services.llm-services.backend = {
    # Vulkan (RADV) build from the llama.cpp flake input.
    package = inputs.llama-cpp.packages.${pkgs.stdenv.hostPlatform.system}.vulkan;

    # Pin the ICD to RADV so the loader cannot pick up AMDVLK/amdgpu-pro if one
    # is ever installed. No HSA overrides: those are ROCm/KFD-only.
    environment = {
      AMD_VULKAN_ICD = "RADV";
    };
  };

  # Vulkan deliberately adds no kernel params of its own. RADV goes through the
  # graphics stack rather than KFD, so the KFD workarounds in ./rocm.nix
  # (cwsr_enable=0, runpm=0) are unnecessary here. Memory sizing and
  # amd_iommu=off are shared and live in ./default.nix.

  # RADV is Mesa's driver, so the graphics stack must be present even though
  # this host is headless.
  hardware.graphics.enable = true;
}

{
  config,
  lib,
  ...
}:

let
  cfg = config.services.llm-services.backend;
in
{
  imports = [
    ./rocm.nix
    ./vulkan.nix
  ];

  options.services.llm-services.backend = {
    enableRocm = lib.mkEnableOption "the ROCm (HIP) llama.cpp backend for the LLM services";
    enableVulkan = lib.mkEnableOption "the Vulkan (RADV) llama.cpp backend for the LLM services";

    package = lib.mkOption {
      type = lib.types.package;
      internal = true;
      description = ''
        The llama.cpp build selected by the active backend. Set by ./rocm.nix or
        ./vulkan.nix depending on which backend is enabled; consumed by the
        individual llama-cpp-* services.
      '';
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      internal = true;
      description = ''
        Backend-specific environment variables (e.g. ROCm HSA overrides) merged
        into each llama-cpp-* systemd service.
      '';
    };

    gttSizeMiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 126976;
      description = ''
        Size of the amdgpu GTT domain in MiB: the ceiling on how much system RAM
        the iGPU may map for buffer objects. On a 128 GB Strix Halo this is what
        decides whether a 70B model fits; the driver default is only a fraction
        of RAM. `ttm.pages_limit` is derived from it (MiB * 256) so TTM does not
        cap the GTT first — that limit is what llama.cpp reports as the device's
        total memory.

        This is a cap, not a reservation: raising it does not take RAM away from
        the CPU, it only permits the GPU to map more — actual consumption is
        bounded by the model plus its KV cache. The previous 100000 MiB left
        ~24 GB headroom to avoid pageflip-timeout freezes, but that is a
        display-pipeline failure mode and these hosts are headless.

        126976 MiB (124 GiB) is the value recommended for a 128 GB Strix Halo by
        https://strix-halo-toolboxes.com/, which pairs it with the same
        ttm.pages_limit ratio derived below.
      '';
    };
  };

  config = lib.mkIf (cfg.enableRocm || cfg.enableVulkan) {
    # Enforce exactly one backend when any is selected.
    assertions = [
      {
        assertion = cfg.enableRocm != cfg.enableVulkan;
        message = "services.llm-services.backend: enable exactly one of enableRocm / enableVulkan.";
      }
    ];

    # Unified-memory sizing. Both backends allocate the model out of GTT, so
    # this is shared; the per-backend files add only their own workarounds.
    boot.kernelParams = [
      "amdgpu.gttsize=${toString cfg.gttSizeMiB}"
      "ttm.pages_limit=${toString (cfg.gttSizeMiB * 256)}" # MiB -> 4 KiB pages

      # Recommended for both backends by https://strix-halo-toolboxes.com/
      # (5-12% on GPU memory access). The cost is the NPU, which nothing here
      # uses, and DMA-attack protection, which is an acceptable trade on a
      # single-tenant machine with no untrusted peripherals.
      "amd_iommu=off"
    ];
  };
}

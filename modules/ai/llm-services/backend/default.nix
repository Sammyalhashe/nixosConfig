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
  };

  # Enforce exactly one backend when any is selected.
  config.assertions = lib.mkIf (cfg.enableRocm || cfg.enableVulkan) [
    {
      assertion = cfg.enableRocm != cfg.enableVulkan;
      message = "services.llm-services.backend: enable exactly one of enableRocm / enableVulkan.";
    }
  ];
}

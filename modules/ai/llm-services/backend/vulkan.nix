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

    # Vulkan needs no HSA overrides or ROCm kernel workarounds; RADV is the
    # default Mesa driver on NixOS.
    environment = { };
  };
}

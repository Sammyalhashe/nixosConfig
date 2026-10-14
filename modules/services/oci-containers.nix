{ lib, ... }:
{
  options.virtualisation.oci-containers.containers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        config.pull = lib.mkDefault "always";
      }
    );
  };
}

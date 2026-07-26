{
  config,
  inputs,
  lib,
  ...
}:

{
  imports = [
    inputs.vicinae.nixosModules.default
  ];

  host.enableVicinae = lib.mkDefault (!config.host.isWsl && !config.host.isHeadless);
}

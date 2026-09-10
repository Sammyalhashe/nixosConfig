{ config, lib, ... }:
{
  # Was four byte-identical hosts/<host>/bluetooth.nix files.
  config = lib.mkIf config.host.enableBluetooth {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    services.blueman.enable = true;
  };
}

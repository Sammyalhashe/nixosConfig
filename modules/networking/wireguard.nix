{ config, lib, ... }:
with lib;
{
  options.enableNixosHostWireguard = mkOption {
    type = types.bool;
    default = false;
    description = "Whether to enable Wireguard configuration for this NixOS host.";
  };

  config = mkIf config.enableNixosHostWireguard {
    sops.secrets.wireguard_starship = {
      owner = "root";
      group = "root";
      mode = "0600";
    };

    networking.wg-quick.interfaces.wg0.configFile = config.sops.secrets.wireguard_starship.path;
  };
}

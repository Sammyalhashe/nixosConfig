{ config, ... }:
{
  sops.secrets.wireguard_starship = {
    owner = "root";
    group = "root";
    mode = "0600";
  };

  networking.wg-quick.interfaces.wg0.configFile = config.sops.secrets.wireguard_starship.path;
}

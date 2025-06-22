{ config, ... }:
{
  networking.wg-quick.interfaces.wg0.configFile = "/etc/wireguard/starship.conf";
}

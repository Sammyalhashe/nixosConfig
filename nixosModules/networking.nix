{ config, lib, ... }:
{
  # Conditional nameserver setting
  networking.nameservers = lib.mkIf config.host.setNameservers (
    [
      "194.242.2.2" # Mullvad Primary
      "194.242.2.4" # Mullvad Secondary
    ]
    ++ config.host.fallbackNameservers
  );
}

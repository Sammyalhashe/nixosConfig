{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Desktop Bitcoin wallet, pointed at the node on mothership rather than a
  # public server -- addresses never leave the LAN.
  #
  # Sparrow's server connection is per-user GUI state (~/.sparrow/config), so it
  # is set once by hand under File -> Preferences -> Server. Two options:
  #
  #   Bitcoin Core   mothership.salh.xyz:8332, cookie or rpcuser auth.
  #                  Needs no extra service; txindex=1 is already set, which is
  #                  what gives Sparrow transaction-input lookups it would
  #                  otherwise only get from an Electrum server.
  #
  #   Private Electrum  mothership.salh.xyz:50001 (electrs). Faster address
  #                  lookups and the same protocol every mobile wallet speaks,
  #                  at the cost of electrs's separate ~56 GB index.
  #
  # Either way the RPC/Electrum port has to be reachable from this host, which
  # is a firewall change on mothership -- neither is exposed by default.
  config = lib.mkIf config.host.enableSparrow {
    environment.systemPackages = [ pkgs.sparrow ];
  };
}

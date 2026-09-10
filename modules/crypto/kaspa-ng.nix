{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Desktop Kaspa wallet. The derivation lives in ../../pkgs/kaspa-ng.nix so
  # ryoku's standalone home-manager config can reuse it.
  #
  # To point it at the node on mothership instead of syncing its own copy of
  # the DAG: in kaspa-ng, switch the node setting from Integrated to Remote and
  # give it mothership's wRPC borsh endpoint,
  #
  #     ws://mothership.salh.xyz:17110
  #
  # which requires host.exposeKaspaToLan on mothership (see ./kaspad.nix).
  # That is per-user GUI state, so there is nothing to declare here.
  config = lib.mkIf config.host.enableKaspaNg {
    environment.systemPackages = [ (import ../../pkgs/kaspa-ng.nix { inherit pkgs; }) ];
  };
}

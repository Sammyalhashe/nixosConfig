{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Bitcoin wallet built around on-chain timelocks: funds stay in a normal
  # descriptor wallet, but a recovery path becomes spendable after N blocks of
  # inactivity. Complements Sparrow rather than replacing it -- Sparrow is the
  # general-purpose wallet, Liana is the inheritance/recovery one.
  #
  # Liana needs a chain backend. Same two choices as Sparrow (see sparrow.nix):
  # Bitcoin Core RPC on mothership.salh.xyz:8332, or an Electrum server. Core
  # is the one that works today -- txindex is on and electrs is not deployed.
  # The backend is chosen in the GUI on first run and stored in per-user state,
  # so there is nothing to declare here.
  config = lib.mkIf config.host.enableLiana {
    # pkgs.liana is the GUI (mainProgram liana-gui) and pkgs.lianad is the
    # headless daemon. A headless host cannot run the GUI, so give it the
    # daemon instead -- on mothership this is what is actually usable over SSH.
    environment.systemPackages = [
      (if config.host.isHeadless then pkgs.lianad else pkgs.liana)
    ];
  };
}

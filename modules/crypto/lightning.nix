{
  config,
  inputs,
  ...
}:
{
  imports = [
    inputs.nix-bitcoin.nixosModules.default
  ];

  # Generate bitcoind/lnd/electrs/rtl credentials into /etc/nix-bitcoin-secrets.
  # Without this (or a deployment method) nix-bitcoin fails an assertion.
  # NOTE: back up that directory -- it holds the LND seed material.
  nix-bitcoin.generateSecrets = true;

  # Lets the main user run bitcoin-cli / lncli without sudo.
  nix-bitcoin.operator = {
    enable = true;
    name = config.host.username;
  };

  services.bitcoind = {
    enable = true;
    txindex = true; # Full transaction index enabled

    # Set to 24000 (24GB) for IBD; drop to 4000 (4GB) after sync completes
    dbCache = 24000;
  };

  services.electrs.enable = true;
  services.lnd.enable = true;

  # Ride The Lightning: the LND web UI supported by nix-bitcoin. Binds to
  # 127.0.0.1:3000, so reach it over an SSH tunnel -- mothership is headless.
  services.rtl = {
    enable = true;
    nodes.lnd.enable = true;
  };
}

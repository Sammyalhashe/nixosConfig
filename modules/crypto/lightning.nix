{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.host;
in
{
  imports = [
    inputs.nix-bitcoin.nixosModules.default
  ];

  config = lib.mkMerge [
    {
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

        # 4 GB steady-state. The 24 GB used during initial block download is
        # only worth it while syncing, and on this host it competes directly
        # with the ~87 GiB LLM -- the two together do not fit in 128 GiB.
        dbCache = 4000;
      };

      # electrs is an Electrum server: it builds an address -> transaction index
      # so on-chain wallets can ask "what does this address own?". Off, because
      # nothing here needs it -- LND talks to bitcoind directly, and Sparrow
      # connects to Bitcoin Core's RPC, where txindex above already provides the
      # transaction-input lookups that would otherwise require an Electrum
      # server. Turning this on is all that is needed to get it (and its
      # firewall port) back; the cost is a separate ~56 GB index.
      services.electrs.enable = false;

      services.lnd = {
        enable = true;
        # Default 8080 collides with open-webui, which binds 0.0.0.0:8080 and so
        # also claims 127.0.0.1:8080. This is the local REST API only -- nothing
        # external connects to it, and RTL derives its endpoint from this option.
        restPort = 8085;
      };

      # Ride The Lightning: the LND web UI supported by nix-bitcoin. Binds to
      # 127.0.0.1:3000, so reach it over an SSH tunnel -- mothership is headless.
      services.rtl = {
        enable = true;
        nodes.lnd.enable = true;
      };
    }

    # LAN exposure, kept here rather than in the host config so the firewall
    # holes live next to the services that need them and appear together with
    # the option that opens them.
    (lib.mkIf cfg.exposeBitcoinToLan {
      services.bitcoind.rpc = {
        address = "0.0.0.0";
        allowip = [ "127.0.0.1" ] ++ cfg.bitcoinLanCidrs;

        # Sparrow reaches Core through its bundled Cormorant bridge, which does
        # not merely read the chain: it creates a watch-only wallet on the node
        # and imports the wallet's descriptors into it. The full set of calls is
        # the @JsonRpcMethod list in Sparrow's
        # net/cormorant/bitcoind/BitcoindClientService.java -- 22 methods, of
        # which nix-bitcoin's `public` user already permits 13.
        #
        # The other nine are wallet RPCs, which `public` omits on purpose. So
        # Sparrow gets its own user rather than eroding the read-only one, and
        # rather than using `privileged`, whose whitelist is empty -- in
        # bitcoind that means no restriction at all, including stop/addnode/
        # setban. This mirrors how nix-bitcoin's own btcpayserver module adds a
        # third RPC user (modules/btcpayserver.nix:115).
        users.sparrow = {
          passwordHMACFromFile = true;
          rpcwhitelist = config.services.bitcoind.rpc.users.public.rpcwhitelist ++ [
            # Cormorant creates and loads a watch-only wallet, then imports the
            # descriptors Sparrow derives from your keys. Private keys stay in
            # Sparrow; the node only ever sees public descriptors.
            "createwallet"
            "loadwallet"
            "unloadwallet"
            "importdescriptors"
            "listdescriptors"
            "listwallets"
            "listwalletdir"
            "getwalletinfo"
            # Wallet-scoped history, polled to track confirmations.
            "listsinceblock"
            "gettransaction"
          ];
        };
      };

      # electrs has no allowlist of its own, so the firewall is the only thing
      # restricting it -- open it solely when electrs is actually enabled.
      services.electrs.address = lib.mkIf config.services.electrs.enable "0.0.0.0";

      networking.firewall.allowedTCPPorts = [
        config.services.bitcoind.rpc.port # 8332 -- Sparrow via Bitcoin Core RPC
      ]
      ++ lib.optional config.services.electrs.enable config.services.electrs.port; # 50001

      # nix-bitcoin only generates passwords for its own two users, so the
      # sparrow user needs its secret wired up explicitly. makeBitcoinRPCPassword
      # takes any name and writes both bitcoin-rpcpassword-<name> (the plaintext
      # Sparrow needs) and bitcoin-HMAC-<name> (what bitcoind stores), see
      # modules/secrets/secrets.nix:93.
      nix-bitcoin.secrets = {
        bitcoin-rpcpassword-sparrow.user = config.services.bitcoind.user;
        bitcoin-HMAC-sparrow.user = config.services.bitcoind.user;
      };
      nix-bitcoin.generateSecretsCmds.bitcoind-sparrow = ''
        makeBitcoinRPCPassword sparrow
      '';
    })

    # Lightning wallets (Zeus). Separate from the bitcoind switch on purpose:
    # this is LND's admin API, and its macaroon is bearer authority over the
    # channel funds. Safe here only because the Cloudflare tunnel reaches this
    # subnet as a *private network* route -- LND's own TLS stays end-to-end.
    # Publishing it as a tunnel "application" instead would terminate TLS at
    # Cloudflare's edge and expose the macaroon in plaintext.
    (lib.mkIf cfg.exposeLndToLan {
      assertions = [
        {
          assertion = cfg.lndLanAddress != "";
          message = "host.exposeLndToLan requires host.lndLanAddress (goes into LND's TLS subjectAltName).";
        }
      ];

      # Prints a QR/URI bundling host, cert and macaroon for the wallet to scan:
      #   lndconnect --host=<lndLanAddress>        # QR
      #   lndconnect --host=<lndLanAddress> --url  # URI
      # Note this also sets services.lnd.restAddress to 0.0.0.0 on our behalf
      # (nix-bitcoin modules/lndconnect.nix), which is what makes REST reachable.
      services.lnd.lndconnect.enable = true;

      # LND only auto-adds its rpcAddress to the certificate, so without this
      # wallets dialling lndLanAddress fail certificate verification.
      services.lnd.certificate.extraIPs = [ cfg.lndLanAddress ];

      networking.firewall.allowedTCPPorts = [
        config.services.lnd.restPort # 8085 -- Zeus et al. gRPC (10009) stays local.
      ];
    })
  ];
}

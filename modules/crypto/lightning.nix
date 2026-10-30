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

  # nixpkgs-unstable rewrote services.i2pd around RFC42 `settings` and dropped
  # `proto`, but nix-bitcoin's netns-isolation module still defines
  # services.i2pd.proto.sam.*. That code sits behind netns-isolation.enable
  # (off here), yet an undeclared option fails evaluation even inside a false
  # mkIf. Declare it as an inert placeholder until nix-bitcoin catches up, and
  # refuse netns-isolation, whose i2pd wiring would silently do nothing.
  options.services.i2pd.proto = lib.mkOption {
    type = lib.types.anything;
    default = { };
    internal = true;
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !config.nix-bitcoin.netns-isolation.enable;
          message = "nix-bitcoin netns-isolation relies on the removed services.i2pd.proto; see the shim in modules/crypto/lightning.nix.";
        }
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

        # 4 GB steady-state. The 24 GB used during initial block download is
        # only worth it while syncing, and on this host it competes directly
        # with the ~87 GiB LLM -- the two together do not fit in 128 GiB.
        dbCache = 4000;
      };

      # electrs is an Electrum server: it builds an address -> transaction index
      # so Electrum-protocol wallets can ask "what does this address own?". LND
      # and Sparrow don't need it (they use bitcoind directly); it's for other
      # wallets. Costs a separate ~56 GB index; opens port 50001 to the LAN.
      services.electrs.enable = true;

      # electrs 0.12 reads blocks through bitcoind's REST interface, which is off
      # by default. REST is read-only public chain data and obeys rpcallowip.
      services.bitcoind.extraConfig = lib.mkIf config.services.electrs.enable ''
        rest=1
      '';

      # The index is ~2900 RocksDB files; the default soft limit of 1024 made
      # electrs crash with "Too many open files" during compaction.
      systemd.services.electrs.serviceConfig.LimitNOFILE = 65536;

      # nix-bitcoin's module still passes --daemon-p2p-addr, which electrs 0.12
      # removed (it fetches blocks over RPC now), so electrs refuses to start.
      # Same command as the module's, minus that flag.
      systemd.services.electrs.serviceConfig.ExecStart =
        let
          cfg = config.services.electrs;
          btc = config.services.bitcoind;
        in
        lib.mkForce ''
          ${config.nix-bitcoin.pkgs.electrs}/bin/electrs \
          --log-filters=INFO \
          --network=${btc.makeNetworkName "bitcoin" "regtest"} \
          --db-dir='${cfg.dataDir}' \
          --daemon-dir='${btc.dataDir}' \
          --electrum-rpc-addr=${cfg.address}:${toString cfg.port} \
          --monitoring-addr=${cfg.address}:${toString cfg.monitoringPort} \
          --daemon-rpc-addr=${btc.rpc.address}:${toString btc.rpc.port} \
          ${cfg.extraArgs}
        '';

      services.lnd = {
        enable = true;
        # Off the default 8080, which is a common port for web UIs. This is the
        # local REST API only -- RTL derives its endpoint from this option.
        restPort = 8085;
      };

      # Ride The Lightning: the LND web UI supported by nix-bitcoin. Binds to
      # 127.0.0.1:3010, so reach it over an SSH tunnel -- mothership is headless.
      services.rtl = {
        enable = true;
        port = 3010;
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

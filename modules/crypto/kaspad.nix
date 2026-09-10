{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.host;

  # nixpkgs has no kaspad, and upstream ships prebuilt linux-amd64 binaries per
  # release, so unpack those rather than building rusty-kaspa from source --
  # the same trade already made for kaspa-ng in ./kaspa-ng.nix.
  #
  # Note this is the *daemon*: ./kaspa-ng.nix packages the GTK desktop wallet,
  # which cannot run on a headless host.
  kaspad = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "kaspad";
    version = "2.0.1";

    src = pkgs.fetchurl {
      url = "https://github.com/kaspanet/rusty-kaspa/releases/download/v${finalAttrs.version}/rusty-kaspa-v${finalAttrs.version}-linux-amd64.zip";
      hash = "sha256-nQrQrtvilnDj4t3mZEYsUm0wotL/cnTRixoxChJ9HBM=";
    };

    nativeBuildInputs = with pkgs; [
      unzip
      autoPatchelfHook
    ];

    buildInputs = with pkgs; [
      stdenv.cc.cc.lib
      openssl
    ];

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      install -Dm755 bin/kaspad       $out/bin/kaspad
      install -Dm755 bin/kaspa-wallet $out/bin/kaspa-wallet
      runHook postInstall
    '';

    meta = {
      description = "Rusty Kaspa full node daemon";
      homepage = "https://github.com/kaspanet/rusty-kaspa";
      mainProgram = "kaspad";
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
      license = lib.licenses.isc;
    };
  });

  # Bind address for the RPC listeners: localhost unless the node is
  # deliberately serving wallets on the LAN.
  rpcHost = if cfg.exposeKaspaToLan then "0.0.0.0" else "127.0.0.1";
in
{
  config = lib.mkIf cfg.enableKaspad (
    lib.mkMerge [
      {
        # Ports (mainnet defaults, from rusty-kaspa kaspad/src/args.rs):
        #   16111  P2P            -- opened below; a node wants inbound peers
        #   16110  gRPC
        #   17110  wRPC borsh     -- what kaspa-ng's "Remote" mode speaks
        #   18110  wRPC JSON
        # None of these collide with bitcoind (8332/8333, 28332/28333), LND
        # (8085/9735/10009), RTL (3000), LiteLLM (4000) or the llama-server
        # instances (8011/8014).
        systemd.services.kaspad = {
          description = "Kaspa full node (kaspad)";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            ExecStart = lib.concatStringsSep " " [
              "${kaspad}/bin/kaspad"
              "--appdir=/var/lib/kaspad"
              # Required for wallet functionality; without it the node cannot
              # answer UTXO queries.
              "--utxoindex"
              "--rpclisten=${rpcHost}:16110"
              "--rpclisten-borsh=${rpcHost}:17110"
            ];

            DynamicUser = true;
            StateDirectory = "kaspad";
            Restart = "on-failure";
            RestartSec = "10s";

            # kaspad only needs its state dir and the network.
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            NoNewPrivileges = true;
          };
        };

        networking.firewall.allowedTCPPorts = [ 16111 ];

        environment.systemPackages = [ kaspad ];
      }

      (lib.mkIf cfg.exposeKaspaToLan {
        # Lets Kaspa NG on homebase/starship/ryoku use this node rather than
        # each syncing its own copy of the DAG.
        #
        # WARNING: kaspad's RPC has no authentication. Unlike bitcoind, which
        # gates JSON-RPC behind rpcauth and an allowip list, anything that can
        # reach these ports can call any RPC method -- including ones that
        # affect the node's operation. There is no allowlist knob to narrow it
        # to host.bitcoinLanCidrs the way ./lightning.nix does, so this is
        # only safe on a trusted LAN and must never be routed to the internet.
        # Wallet keys are held by kaspa-ng, not the node, so funds are not
        # directly at risk -- node availability is.
        networking.firewall.allowedTCPPorts = [
          16110
          17110
        ];
      })
    ]
  );
}

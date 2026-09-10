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
in
{
  config = lib.mkIf cfg.enableKaspad {
    # Ports (mainnet defaults, from rusty-kaspa kaspad/src/args.rs):
    #   16111  P2P            -- opened below; a node wants inbound peers
    #   16110  gRPC           -- localhost only
    #   17110  wRPC borsh     -- localhost only
    #   18110  wRPC JSON      -- localhost only
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
          "--rpclisten=127.0.0.1:16110"
          "--rpclisten-borsh=127.0.0.1:17110"
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
  };
}

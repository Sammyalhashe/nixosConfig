{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.host;

  # Upstream ships prebuilt linux-amd64 binaries per release; building from
  # source needs Go, Rust, a C toolchain and Task, so unpack those instead (the
  # same trade as ./kaspad.nix). Only glibc and libgcc_s are linked.
  pearl = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "pearl";
    version = "1.5.7";

    src = pkgs.fetchurl {
      url = "https://github.com/pearl-research-labs/pearl/releases/download/v${finalAttrs.version}/pearl-linux-amd64-v${finalAttrs.version}.tar.gz";
      hash = "sha256-Stth5sz1YdV7EdowQyWSLwjnV2BczH/p/cZ81+Lcqw0=";
    };

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      for b in pearld prlctl oyster oystercli; do
        install -Dm755 "$b" "$out/bin/$b"
      done
      runHook postInstall
    '';

    meta = {
      description = "Pearl full node (pearld), wallet (oyster) and CLI tools";
      homepage = "https://github.com/pearl-research-labs/pearl";
      mainProgram = "pearld";
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
      license = lib.licenses.isc;
    };
  });

  # Default P2P ports per network, from the upstream README.
  p2pPort =
    {
      mainnet = 44108;
      testnet = 44110;
      testnet2 = 44112;
      simnet = 18555;
      regtest = 18444;
    }
    .${cfg.pearlNetwork};

  networkFlag = lib.optionalString (cfg.pearlNetwork != "mainnet") "--${cfg.pearlNetwork}";

  stateDir = "/var/lib/pearld";
  confFile = "${stateDir}/pearld.conf";

  # RPC is disabled unless credentials exist, so mint them once on first start.
  # The file holds only rpcuser/rpcpass, which prlctl also understands:
  #   prlctl -C /var/lib/pearld/pearld.conf --notls getblockchaininfo
  ensureRpcCredentials = pkgs.writeShellScript "pearld-ensure-rpc-credentials" ''
    set -eu
    umask 027
    if [ ! -s ${confFile} ]; then
      pass=$(${pkgs.coreutils}/bin/head -c 32 /dev/urandom | ${pkgs.coreutils}/bin/base64 | ${pkgs.coreutils}/bin/tr -dc 'A-Za-z0-9')
      printf 'rpcuser=pearl\nrpcpass=%s\n' "$pass" > ${confFile}
    fi
  '';
in
{
  config = lib.mkIf cfg.enablePearld {
    users.users.pearld = {
      isSystemUser = true;
      group = "pearld";
      home = stateDir;
    };
    users.groups.pearld = { };
    # Lets the login user read the RPC credentials for prlctl/oyster.
    users.users.${cfg.username}.extraGroups = [ "pearld" ];

    systemd.services.pearld = {
      description = "Pearl full node (pearld, ${cfg.pearlNetwork})";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStartPre = ensureRpcCredentials;
        ExecStart = lib.concatStringsSep " " (
          [
            "${pearl}/bin/pearld"
            "--configfile=${confFile}"
            "--datadir=${stateDir}/data"
            "--logdir=${stateDir}/logs"
            # RPC stays on localhost, where pearld permits plain HTTP.
            "--rpclisten=127.0.0.1"
            "--notls"
            "--txindex"
          ]
          ++ lib.optional (networkFlag != "") networkFlag
        );

        User = "pearld";
        Group = "pearld";
        StateDirectory = "pearld";
        StateDirectoryMode = "0750";
        Restart = "on-failure";
        RestartSec = "10s";

        # The initial sync validates signatures on every core; keep that behind
        # the desktop, as xmrig already is.
        Nice = 19;
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";

        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };

    # A full node wants inbound peers; RPC is never opened.
    networking.firewall.allowedTCPPorts = [ p2pPort ];

    environment.systemPackages = [ pearl ];
  };
}

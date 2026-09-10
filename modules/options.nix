{ config, lib, ... }:

{
  options.host = {
    username = lib.mkOption {
      type = lib.types.str;
      default = "salhashemi2";
      description = "The username of the primary user.";
    };

    isWsl = lib.mkEnableOption "Whether the host is running in WSL.";

    isHeadless = lib.mkEnableOption "Whether the host is headless (no GUI/Steam).";

    enableGreetd = lib.mkEnableOption "Whether to use Greetd.";

    homeManagerHostname = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = "The hostname to use for Home Manager configuration files.";
    };

    setNameservers = lib.mkEnableOption "Whether to explicitly set nameservers via networking.nameservers.";

    fallbackNameservers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "A list of additional nameservers to append as fallbacks.";
    };

    enableKDE = lib.mkEnableOption "Whether to install KDE Plasma.";
    enableMango = lib.mkEnableOption "Whether to install Mango desktop.";
    enableHyprland = lib.mkEnableOption "Whether to install Hyprland.";

    enableMonitoring = lib.mkEnableOption "Whether to enable the monitoring stack (Cockpit, Grafana, Loki, Alloy).";

    enableBreezy = lib.mkEnableOption "Whether to enable Breezy Desktop XR glasses support.";

    enableCloudflareWarp = lib.mkEnableOption "Whether to enable cloudflare-warp daemon and install the client application";

    enableCoinbaseSweep = lib.mkEnableOption "Whether to enable the automated weekly Coinbase self-custody sweep service.";

    enableKaspaNg = lib.mkEnableOption "Whether to install the Kaspa NG desktop node/wallet.";

    enableVicinae = lib.mkEnableOption "Whether to enable Raycast alt Vicinae.";

    enableHardwareWallets = lib.mkEnableOption "Whether to enable hardware wallet support (Ledger, Trezor, OneKey).";

    enableSparrow = lib.mkEnableOption "Whether to install the Sparrow Bitcoin wallet.";

    enableLiana = lib.mkEnableOption "Whether to install the Liana timelock Bitcoin wallet (GUI, or lianad on headless hosts).";

    enableKaspad = lib.mkEnableOption "Whether to run a kaspad (rusty-kaspa) node.";

    exposeKaspaToLan = lib.mkEnableOption ''
      Whether to bind kaspad's RPC listeners to 0.0.0.0 and open them so Kaspa
      NG on other hosts can use this node instead of syncing its own DAG.
      kaspad's RPC is UNAUTHENTICATED -- trusted LAN only, never the internet.
      Opens the corresponding firewall ports -- see modules/crypto/kaspad.nix
    '';

    exposeBitcoinToLan = lib.mkEnableOption ''
      Whether to let other hosts on the LAN reach bitcoind's JSON-RPC (and
      electrs, when enabled) so wallets like Sparrow can use this node. Opens
      the corresponding firewall ports -- see modules/crypto/lightning.nix
    '';

    exposeLndToLan = lib.mkEnableOption ''
      Whether to let Lightning wallets (Zeus, Alby) reach LND's REST API from
      the LAN -- and, via the Cloudflare tunnel's private-network route, from
      WARP clients off-site. This is LND's *admin* interface: the macaroon it
      hands out is unrestricted authority over channel funds, so it is
      deliberately separate from exposeBitcoinToLan
    '';

    lndLanAddress = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "11.125.37.101";
      description = ''
        Address wallets will dial LND on. Added to the TLS certificate's
        subjectAltName -- without it clients reject the connection, since LND
        only auto-adds its rpcAddress. Required when exposeLndToLan is set.
      '';
    };

    bitcoinLanCidrs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "11.125.37.0/24" ];
      description = ''
        Sources permitted to make bitcoind JSON-RPC calls, on top of localhost.
        Only consulted when exposeBitcoinToLan is set.
      '';
    };

    enableBluetooth = lib.mkEnableOption "Whether to enable Bluetooth (bluez + blueman).";

    enableNvidia = lib.mkEnableOption "Whether to enable the proprietary NVIDIA driver.";

    enableWebdav = lib.mkEnableOption "Whether to mount the Nextcloud WebDAV share via davfs2/autofs.";

    enableSnap = lib.mkEnableOption "Whether to enable snap.";
  };
}

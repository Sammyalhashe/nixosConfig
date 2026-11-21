{ config, lib, ... }:
let
  user = config.host.username;
  placeholder = config.sops.placeholder;
  onEveryEvmChain = address: {
    ethereum = address;
    base = address;
    avalanche = address;
  };
in
{
  # Addresses stay in sops; the public repo only names which secret feeds which network.
  config = lib.mkIf config.host.enableWalletWatcherConfig {
    sops.secrets.SAMMYS_MULTISIG_BTC_DESCRIPTOR = { };
    sops.secrets.ZERION_API_KEY.owner = user;
    sops.secrets.WALLET_WATCHER_BITCOIND_RPCPASSWORD.owner = user;

    sops.templates."wallet-watcher.json" = {
      content = config.home-manager.users.${user}.programs.wallet-watcher.configJson;
      owner = user;
    };

    home-manager.users.${user}.programs.wallet-watcher = {
      wallets = {
        Tangem = onEveryEvmChain placeholder.TANGEM_AVAX // {
          solana = placeholder.TANGEM_SOL;
          sui = placeholder.TANGEM_SUI;
        };
        Keystone = onEveryEvmChain placeholder.KEYSTONE_ETH // {
          bitcoin = placeholder.KEYSTONE_BTC;
          sui = placeholder.KEYSTONE_SUI;
        };
        Rocketship = onEveryEvmChain placeholder.ROCKETSHIP_ETH // {
          bitcoin = placeholder.ROCKETSHIP_BTC;
          solana = placeholder.ROCKETSHIP_SOL;
          sui = placeholder.ROCKETSHIP_SUI;
        };
        "Safe DeFi vault" = {
          ethereum = placeholder.SAFE_DEFI_VAULT;
          base = placeholder.SAFE_DEFI_VAULT;
        };
        "Squads vault".solana = placeholder.SQUADS_SOL_VAULT;
        "BTC multisig".bitcoin = placeholder.SAMMYS_MULTISIG_BTC_DESCRIPTOR;
      };
      configFile = config.sops.templates."wallet-watcher.json".path;
      zerionApiKeyFile = config.sops.secrets.ZERION_API_KEY.path;
      # mothership's bitcoind; the walletwatcher RPC user is in modules/crypto/lightning.nix.
      bitcoind = {
        url = "http://11.125.37.101:8332";
        user = "walletwatcher";
        passwordFile = config.sops.secrets.WALLET_WATCHER_BITCOIND_RPCPASSWORD.path;
      };
    };
  };
}

{
  config,
  inputs,
  ...
}:
let
  home = config.home.homeDirectory;
in
{
  imports = [ inputs.trading-bot-flake.homeManagerModules.default ];

  services.trading-bot = {
    enable = true;
    mode = "live";
    ethereum.enable = true;

    # Two Coinbase keys: the trader key for the live bot and PnL, the older
    # key for the report/notifier and the timer fallback.
    coinbaseApiJson = "${home}/cdb_api_key.json";
    ws.coinbaseApiJson = "${home}/cdb_trader_api_key.json";
    pnlReport.coinbaseApiJson = "${home}/cdb_trader_api_key.json";

    environmentFiles = [
      "/run/secrets/rendered/openclaw-env"
      # BASE_RPC_URL: the Chainstack Base node (its URL embeds an access key).
      "/run/secrets/rendered/coinbase-trader-env"
    ];

    # Everything else uses the defaults in the bot's config/trading_config.py.
    settings = {
      STRATEGY = "trend_following";
      SHORT_WINDOW = 21;
      LONG_WINDOW = 55;
      MAX_CONCURRENT_POSITIONS = 5;
      ONCHAIN_MAX_SWAP_USD = 25;
      ONCHAIN_ROUTER = "aerodrome";
      ATR_STOP_MULTIPLIER = 2.5;
      ATR_STOP_MIN_PCT = 0.06;
      STOPOUT_COOLDOWN_HOURS = 12;
    };

    notifier.enable = true;
    pnlReport = {
      enable = true;
      # Read on demand by the hermes agent, which has ACL access to this dir.
      snapshotFile = "${home}/projects/trading-pnl/snapshot.json";
    };
    derivativesCollector.enable = true;
  };
}

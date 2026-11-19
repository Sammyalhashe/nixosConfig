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
      ONCHAIN_ROUTER = "zerox";
      # Measured $25 round trips via 0x ran 0.3-0.94% (incl. 0x's 0.15%/leg).
      ONCHAIN_ROUND_TRIP_FEE_PCT = 0.008;
      # Measured Coinbase fills (Nov 2026): ~0.11% per side, maker and aggressive-limit alike.
      ROUND_TRIP_FEE_PCT = 0.0022;
      ATR_STOP_MULTIPLIER = 2.5;
      ATR_STOP_MIN_PCT = 0.06;
      STOPOUT_COOLDOWN_HOURS = 12;
      # /status /pause /resume /flatten from the owner's Telegram chat; trading-botctl works regardless.
      CONTROL_TELEGRAM = true;
    };

    # Forward test of the daily BTC trend strategy (selected in trading-bot-flake's
    # backtesting/daily_trend_grid.py) on a simulated $10k ledger; places no real orders.
    paper = {
      enable = true;
      startingCash = 10000;
      settings = {
        STRATEGY = "daily_trend";
        DAILY_TREND_ASSETS = "BTC";
        DAILY_TREND_FILTER = "sma:50";
        MAX_CONCURRENT_POSITIONS = 1;
        ROUND_TRIP_FEE_PCT = 0.0022;
        PAPER_FEE_PER_SIDE = 0.0011;
      };
      # Same strategy at CoW-on-Base costs (live tests: ~0–5 bps round trip vs ~22 on Coinbase).
      variants.cow = {
        ROUND_TRIP_FEE_PCT = 0.0005;
        PAPER_FEE_PER_SIDE = 0.00025;
      };
    };

    notifier.enable = true;
    pnlReport = {
      enable = true;
      # Read on demand by the hermes agent, which has ACL access to this dir.
      snapshotFile = "${home}/projects/trading-pnl/snapshot.json";
    };
    derivativesCollector.enable = true;
    # Hourly quote-only comparison of Base DEX vs Coinbase round-trip cost;
    # `onchain-cost-report` summarises it. 0x is included only if ZEROX_API_KEY is set.
    costProbe.enable = true;
  };
}

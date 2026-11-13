{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = config.host.username;
  reportDir = "/home/${user}/portfolio-reports";
  yaml = pkgs.formats.yaml { };

  # Report-only rests on these allowlists: the Coinbase API key's own
  # permissions are unverified, and Robinhood has a single "internal" scope.
  # Robinhood's "none" matches no tool until its read-only names are known.
  readOnlyTools = {
    coinbase = [
      "coinbase_api_key_permissions"
      "coinbase_portfolios_list"
      "coinbase_portfolios_get"
      "coinbase_balance"
      "coinbase_orders_list"
      "coinbase_orders_get"
      "coinbase_orders_fills"
      "coinbase_convert_get"
      "coinbase_products_list"
      "coinbase_products_get"
      "coinbase_products_ticker"
      "coinbase_products_best_bid_ask"
      "coinbase_products_candles"
      "coinbase_fees"
      "coinbase_settlements"
    ];
    robinhood = [ "none" ];
  };

  coinbaseExtension = {
    # The local CDP CLI with the existing API key, so no browser sign-in. It
    # ignores --key-file, so the runner passes the key through COINBASE_KEY_*.
    type = "stdio";
    name = "coinbase";
    cmd = "${pkgs.nodejs_22}/bin/npx";
    args = [
      "--yes"
      "@coinbase/coinbase-cli@0.0.11"
      "mcp"
    ];
    env_keys = [
      "COINBASE_KEY_ID"
      "COINBASE_KEY_SECRET"
      "COINBASE_ENV"
      "COINBASE_CONFIG_DIR"
      "COINBASE_NO_UPDATE_CHECK"
      "COINBASE_NO_HISTORY"
    ];
    timeout = 300;
    available_tools = readOnlyTools.coinbase;
  };

  robinhoodExtension = tools: {
    type = "streamable_http";
    name = "robinhood";
    uri = "https://agent.robinhood.com/mcp/trading";
    timeout = 300;
    available_tools = tools;
  };

  # Allowing only "none" connects (and signs in) yet exposes nothing.
  signinRecipe = yaml.generate "portfolio-signin-robinhood.yaml" {
    version = "1.0.0";
    title = "Portfolio broker sign-in (robinhood)";
    description = "Connects Robinhood so its OAuth token gets stored";
    prompt = "Reply with the single word: connected";
    extensions = [ (robinhoodExtension [ "none" ]) ];
  };

  reportRecipe = yaml.generate "portfolio-report.yaml" {
    version = "1.0.0";
    title = "Daily portfolio report";
    description = "Report-only analysis of Coinbase and Robinhood holdings against macro, news and sentiment";
    parameters = [
      {
        key = "report_date";
        input_type = "string";
        requirement = "required";
        description = "Date of the report";
      }
      {
        key = "market_data";
        input_type = "string";
        requirement = "required";
        description = "Source-tagged market data collected for this report";
      }
    ];
    settings.temperature = 0.2;
    instructions = ''
      You are a careful portfolio analyst writing a read-only report for the
      account owner. You never place, edit or cancel orders or move funds, and
      you never claim to have done so. Suggestions are for the owner to act on.
      Only state facts that come from your tools or the market data provided,
      and tag each with its source in brackets, e.g. [FRED], [Coinbase].
      If data is missing or a tool fails, say so instead of guessing.
      Use only the broker tools and the market data; never call load_skill.
    '';
    prompt = ''
      Write the portfolio report for {{ report_date }}.

      1. Read current holdings, balances and recent orders from Coinbase and
         Robinhood. Compute each position's value and share of the total.
      2. Using the market data below, assess the macro backdrop, upcoming
         events, news relevant to the holdings, and sentiment.
      3. Suggest actions (hold, trim, add, rebalance, watch), each with its
         reasoning, the sources it rests on, and the main risk.

      Format, in Markdown:
      - The very first line is "SUMMARY: " followed by at most 400 characters
        covering total value, the biggest change or risk, and the top suggestion.
      - Then sections: Holdings, Macro, News & sentiment, Suggested actions,
        Data gaps.

      Market data:

      {{ market_data }}
    '';
    extensions = [
      coinbaseExtension
      (robinhoodExtension readOnlyTools.robinhood)
    ];
  };

  # Shared by the timer and manual runs: the job uses mothership's local model,
  # never the public mesh, because the prompt contains the portfolio.
  gooseEnv = ''
    export GOOSE_PROVIDER=openai
    export OPENAI_HOST=http://127.0.0.1:4000
    export OPENAI_BASE_PATH=v1/chat/completions
    export OPENAI_API_KEY=none
    export GOOSE_MODEL=qwen3.8
    export GOOSE_MODE=auto
    export GOOSE_DISABLE_KEYRING=1
    export GOOSE_OAUTH_CALLBACK_PORT=8765
  '';

  signin = pkgs.writeShellApplication {
    name = "portfolio-report-signin";
    runtimeInputs = [ pkgs.goose-cli ];
    text = ''
      ${gooseEnv}
      echo "Open the Robinhood sign-in link Goose prints in a browser that can reach"
      echo "127.0.0.1:8765 on mothership (e.g. ssh -L 8765:127.0.0.1:8765)."
      goose run --recipe ${signinRecipe} --no-session
    '';
  };

  report = pkgs.writeShellApplication {
    name = "portfolio-report";
    runtimeInputs = [
      pkgs.goose-cli
      pkgs.python3
      pkgs.curl
      pkgs.coreutils
      pkgs.gnused
      # coinbase-cli's entry point runs `node` from PATH.
      pkgs.nodejs_22
    ];
    text = ''
      ${gooseEnv}
      export FRED_API_KEY_FILE=${config.sops.secrets.FRED_API_KEY.path}
      export FINNHUB_API_KEY_FILE=${config.sops.secrets.FINNHUB_API_KEY.path}
      COINBASE_KEY_ID=$(cat ${config.sops.secrets.cb_hardware_maker_org_name.path})
      COINBASE_KEY_SECRET=$(cat ${config.sops.secrets.cb_hardware_maker_key.path})
      COINBASE_CONFIG_DIR=$(mktemp -d)
      trap 'rm -rf "$COINBASE_CONFIG_DIR"' EXIT
      export COINBASE_KEY_ID COINBASE_KEY_SECRET COINBASE_CONFIG_DIR
      export COINBASE_ENV=live COINBASE_NO_UPDATE_CHECK=1 COINBASE_NO_HISTORY=1
      day=$(date +%F)
      out=${reportDir}/$day
      mkdir -p "$out"

      python3 ${./fetch_data.py} > "$out/market-data.md"
      # Braces would be read as template syntax; a single argv entry caps at 128 KiB.
      data=$(head -c 60000 "$out/market-data.md" | tr '{}' '()')

      notify() {
        local query=$1
        shift
        curl -fsS -H "Authorization: Bearer $(cat ${config.sops.secrets.NTFY_JOB_TOKEN.path})" "$@" \
          "https://ntfy.salh.xyz/portfolio$query" > /dev/null
      }

      if ! goose run --recipe ${reportRecipe} --no-session --quiet --max-turns 40 \
          --params report_date="$day" --params market_data="$data" \
          > "$out/transcript.md" 2> "$out/goose.log"; then
        notify "" -H "Title: Portfolio report failed ($day)" -H "Tags: warning" \
          -d "Goose exited with an error; see $out/goose.log on mothership."
        exit 1
      fi

      # The report starts at its SUMMARY line; tool output before it stays in the transcript.
      sed -n '/^SUMMARY:/,$p' "$out/transcript.md" > "$out/report.md"
      [ -s "$out/report.md" ] || cp "$out/transcript.md" "$out/report.md"
      summary=$(sed -n 's/^SUMMARY: *//p' "$out/report.md" | head -n 1 | cut -c1-400)
      message=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' \
        "''${summary:-Report ready; no summary line found.}")
      notify "?message=$message" -H "Title: Portfolio report $day" -H "Tags: chart_with_upwards_trend" \
        -H "Filename: portfolio-$day.md" -T "$out/report.md"
    '';
  };
in
{
  sops.secrets =
    lib.genAttrs
      [
        "FRED_API_KEY"
        "FINNHUB_API_KEY"
        "NTFY_JOB_TOKEN"
        "cb_hardware_maker_org_name"
        "cb_hardware_maker_key"
      ]
      (_: {
        owner = user;
      });

  environment.systemPackages = [
    report
    signin
  ];

  systemd.services.portfolio-report = {
    description = "Daily report-only portfolio analysis";
    after = [
      "network-online.target"
      "litellm.service"
    ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = user;
      ExecStart = lib.getExe report;
      # Cold prompts take minutes on the local model, and the report makes many tool calls.
      TimeoutStartSec = "2h";
    };
  };

  systemd.timers.portfolio-report = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 08:30:00 America/New_York";
      Persistent = true;
    };
  };
}

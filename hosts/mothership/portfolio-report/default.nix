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

  # Report-only: Coinbase gets read scopes; Robinhood offers a single
  # "internal" scope, so its allowlist is the only thing keeping trades out.
  # "none" matches no tool; replaced by read-only names once they are known.
  readOnlyTools = {
    coinbase = [ "none" ];
    robinhood = [ "none" ];
  };

  brokerExtensions = tools: [
    {
      type = "streamable_http";
      name = "coinbase";
      uri = "https://agents.coinbase.com/mcp";
      timeout = 300;
      scopes = [
        "mcp:portfolios:read"
        "mcp:accounts:read"
        "mcp:orders:read"
        "mcp:trades:read"
        "mcp:products:read"
      ];
      available_tools = tools.coinbase;
    }
    {
      type = "streamable_http";
      name = "robinhood";
      uri = "https://agent.robinhood.com/mcp/trading";
      timeout = 300;
      available_tools = tools.robinhood;
    }
  ];

  # An allowlist naming no real tool connects the servers (and runs OAuth)
  # while exposing nothing to the model.
  signinRecipe = yaml.generate "portfolio-signin.yaml" {
    version = "1.0.0";
    title = "Portfolio broker sign-in";
    description = "Connects Coinbase and Robinhood so their OAuth tokens get stored";
    prompt = "Reply with the single word: connected";
    extensions = brokerExtensions {
      coinbase = [ "none" ];
      robinhood = [ "none" ];
    };
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
    extensions = brokerExtensions readOnlyTools;
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
      echo "Open each sign-in link Goose prints in a browser that can reach"
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
    ];
    text = ''
      ${gooseEnv}
      export FRED_API_KEY_FILE=${config.sops.secrets.FRED_API_KEY.path}
      export FINNHUB_API_KEY_FILE=${config.sops.secrets.FINNHUB_API_KEY.path}
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
          > "$out/report.md" 2> "$out/goose.log"; then
        notify "" -H "Title: Portfolio report failed ($day)" -H "Tags: warning" \
          -d "Goose exited with an error; see $out/goose.log on mothership."
        exit 1
      fi

      summary=$(sed -n 's/^SUMMARY: *//p' "$out/report.md" | head -n 1 | cut -c1-400)
      message=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' \
        "''${summary:-Report ready; no summary line found.}")
      notify "?message=$message" -H "Title: Portfolio report $day" -H "Tags: chart_with_upwards_trend" \
        -H "Filename: portfolio-$day.md" -T "$out/report.md"
    '';
  };
in
{
  sops.secrets = lib.genAttrs [ "FRED_API_KEY" "FINNHUB_API_KEY" "NTFY_JOB_TOKEN" ] (_: {
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

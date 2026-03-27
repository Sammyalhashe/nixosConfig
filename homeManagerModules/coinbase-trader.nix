{
  config,
  pkgs,
  lib,
  ...
}:
let
  user = "salhashemi2";
  repoDir = "/home/${user}/trading-bot-flake";
in
{
  # Ensure necessary packages are available
  home.packages = with pkgs; [
    nix
    git
  ];

  # 1. Activation script to clone/update the trading bot repository
  home.activation.installTradingBot = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    PATH=$PATH:${pkgs.openssh}/bin:${pkgs.iputils}/bin
    if ${pkgs.iputils}/bin/ping -c 1 github.com &>/dev/null; then
      if [ ! -d "${repoDir}" ]; then
        ${pkgs.git}/bin/git clone https://github.com/Sammyalhashe/trading-bot-flake "${repoDir}"
      else
        cd "${repoDir}" && ${pkgs.git}/bin/git pull
      fi
    else
      echo "Network unreachable, skipping trading-bot-flake update"
    fi
  '';

  # 2. Systemd user service to run the trading bot (Disabled by default, replaced by WS)
  systemd.user.services.coinbase-trader = {
    Unit = {
      Description = "Run Coinbase Trading Bot";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      WorkingDirectory = repoDir;
      Environment = [
        "TRADING_MODE=live"
        "ENABLE_ETHEREUM=true"
        "COINBASE_API_JSON=/home/${user}/cdb_api_key.json"
        "STRATEGY=mean_reversion"
        # All risk/strategy params use Python defaults from config/trading_config.py
        # To override any default, add the env var here (see config/trading_config.py)
      ];
      EnvironmentFile = "/run/secrets/rendered/openclaw-env";
      # Wait for network to be truly available (timeout after 60s)
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'for i in {1..12}; do if ${pkgs.iputils}/bin/ping -c 1 api.coinbase.com &>/dev/null; then exit 0; fi; sleep 5; done; exit 1'";
      # Use nix run directly on the flake
      ExecStart = "${pkgs.nix}/bin/nix run ${repoDir} --extra-experimental-features 'nix-command flakes'";
    };
  };

  # 2b. Systemd user service for WebSocket mode (long-lived, real-time exits)
  systemd.user.services.coinbase-trader-ws = {
    Unit = {
      Description = "Coinbase Trading Bot (WebSocket mode)";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
      Conflicts = [ "coinbase-trader.service" "coinbase-trader.timer" ];
    };
    Service = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "10s";
      WorkingDirectory = repoDir;
      Environment = [
        "TRADING_MODE=live"
        "ENABLE_ETHEREUM=true"
        "COINBASE_API_JSON=/home/${user}/cdb_api_key.json"
        "STRATEGY=mean_reversion"
      ];
      EnvironmentFile = "/run/secrets/rendered/openclaw-env";
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'for i in {1..12}; do if ${pkgs.iputils}/bin/ping -c 1 api.coinbase.com &>/dev/null; then exit 0; fi; sleep 5; done; exit 1'";
      ExecStart = "${pkgs.nix}/bin/nix run ${repoDir} --extra-experimental-features 'nix-command flakes' -- --ws";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # 3. Systemd user timer to run the bot every 3 minutes (Disabled by default)
  systemd.user.timers.coinbase-trader = {
    Unit = {
      Description = "Run Coinbase Trading Bot every 3 minutes";
    };
    Timer = {
      OnCalendar = "*:0/3";
      Persistent = true;
    };
  };

  # 4. Systemd user service for the trading report (optional but good to have)
  systemd.user.services.coinbase-report = {
    Unit = {
      Description = "Run Coinbase Trading Report";
    };
    Service = {
      Type = "oneshot";
      WorkingDirectory = repoDir;
      Environment = [
        "COINBASE_API_JSON=/home/${user}/cdb_api_key.json"
      ];
      ExecStart = "${pkgs.nix}/bin/nix run ${repoDir}#report --extra-experimental-features 'nix-command flakes'";
    };
  };
}

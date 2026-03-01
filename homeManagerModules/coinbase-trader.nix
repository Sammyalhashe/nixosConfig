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
    if [ ! -d "${repoDir}" ]; then
      ${pkgs.git}/bin/git clone https://github.com/Sammyalhashe/trading-bot-flake "${repoDir}"
    else
      cd "${repoDir}" && ${pkgs.git}/bin/git pull
    fi
  '';

  # 2. Systemd user service to run the trading bot
  systemd.user.services.coinbase-trader = {
    Unit = {
      Description = "Run Coinbase Trading Bot";
      After = [ "network.target" ];
    };
    Service = {
      Type = "oneshot";
      WorkingDirectory = repoDir;
      Environment = [
        "TRADING_MODE=live"
        "COINBASE_API_JSON=/home/${user}/cdb_api_key.json"
      ];
      # Use nix run directly on the flake
      ExecStart = "${pkgs.nix}/bin/nix run ${repoDir} --extra-experimental-features 'nix-command flakes'";
    };
  };

  # 3. Systemd user timer to run the bot every 5 minutes
  systemd.user.timers.coinbase-trader = {
    Unit = {
      Description = "Run Coinbase Trading Bot every 5 minutes";
    };
    Timer = {
      OnCalendar = "*:0/5";
      Persistent = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
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

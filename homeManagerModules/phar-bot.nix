{
  config,
  pkgs,
  lib,
  ...
}:
let
  user = "salhashemi2";
  repoDir = "/home/${user}/Projects/phar-liquidity-bot";
in
{
  # 1. Systemd user service for the PHAR liquidity bot
  systemd.user.services.phar-liquidity-bot = {
    Unit = {
      Description = "Phar Liquidity Bot (WETH.e/AVAX on Pharaoh V3)";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      WorkingDirectory = repoDir;
      Environment = [
        "ETH_PRIVATE_KEY_FILE=/run/secrets/rendered/phar-bot-private-key"
        "MAIN_WALLET=0x4FA03c9726b2813EF857392Da80517935beBb5BC"
        "WETH_AVAX_POOL_ADDRESS=0xff0855a9027f5f5c2bbacc4aac477afbeeefbea9"
      ];
      EnvironmentFile = "/run/secrets/rendered/openclaw-env";
      # Wait for network and API availability (timeout 120s)
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'for i in {1..24}; do if ${pkgs.iputils}/bin/ping -c 1 api.alchemy.com &>/dev/null; then exit 0; fi; sleep 5; done; exit 1'";
      # Run the bot script
      ExecStart = "${pkgs.nix}/bin/nix run ${repoDir}#default --extra-experimental-features 'nix-command flakes'";
    };
  };

  # 2. Systemd user timer to run every 5 minutes
  systemd.user.timers.phar-liquidity-bot = {
    Unit = {
      Description = "Run PHAR Liquidity Bot every 5 minutes";
    };
    Timer = {
      OnCalendar = "*:0/5";
      Persistent = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  # 3. SOPS secret for private key (relative to flake root)
  sops.secrets.phar-bot-private-key = {
    sopsFile = ../../secrets/phar-bot-secrets.yaml;
    format = "json";
  };
}

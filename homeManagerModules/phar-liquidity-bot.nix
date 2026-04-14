{
  config,
  pkgs,
  lib,
  ...
}:
let
  user = "salhashemi2";
  repoDir = "/home/${user}/Projects/phar-liquidity-bot";

  # Pool to trade. Must match a key in POOL_REGISTRY in config.ts:
  #   weth-wavax   Vol/Liq 1.79x  IL=Medium    Rebalances=High    ← current
  #   wavax-usdc   Vol/Liq 4.56x  IL=Medium    Rebalances=High    ← highest fee APR
  #   savax-wavax  Vol/Liq 1.03x  IL=VeryLow   Rebalances=VeryLow ← lowest gas spend
  currentPool = "weth-wavax"; # ← change this to switch pools
in
{
  home.packages = with pkgs; [
    nix
    git
  ];

  # Clone/update repo and install npm dependencies
  home.activation.installPharBot = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    PATH=$PATH:${pkgs.openssh}/bin:${pkgs.iputils}/bin
    if ${pkgs.iputils}/bin/ping -c 1 github.com &>/dev/null; then
      if [ ! -d "${repoDir}" ]; then
        ${pkgs.git}/bin/git clone git@github.com:Sammyalhashe/phar-liquidity-bot.git "${repoDir}"
      else
        cd "${repoDir}" && ${pkgs.git}/bin/git pull
      fi
      # npm deps are bundled by the flake — no npm install needed here
    else
      echo "Network unreachable, skipping phar-liquidity-bot update"
    fi
  '';

  # Systemd user service — continuous EOA mode
  systemd.user.services.phar-liquidity-bot = {
    Unit = {
      Description = "Phar Liquidity Rebalancing Bot (EOA mode)";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "30s";
      WorkingDirectory = repoDir;
      Environment = [
        "POOL_NAME=${currentPool}"
      ];
      EnvironmentFile = "${repoDir}/.env";
      # Wait for Avalanche RPC to be reachable before starting
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'for i in {1..12}; do if ${pkgs.iputils}/bin/ping -c 1 api.avax.network &>/dev/null; then exit 0; fi; sleep 5; done; exit 1'";
      ExecStart = "${pkgs.nix}/bin/nix run ${repoDir} --extra-experimental-features 'nix-command flakes' -- --mode=eoa";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}

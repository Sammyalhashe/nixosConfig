{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  botPkg = inputs.phar-liquidity-bot.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Env file holding the RPC URL and the signing key. Deliberately NOT inside a
  # source checkout -- it used to live at ~/Projects/phar-liquidity-bot/.env,
  # which coupled the service to a working copy that home-manager cloned and
  # rebased on every activation.
  envFile = "${config.xdg.configHome}/phar-liquidity-bot/.env";

  # DEX to trade on. Must match a key in DEX_REGISTRY in config.ts:
  #   pharaoh   — Algebra Integral concentrated liquidity, PHAR rewards via gauge
  #   blackhole — Algebra Integral (same math as Pharaoh), BLACK rewards
  #   lfj       — Trader Joe Liquidity Book (discrete bins), fees accrue in-place
  currentDex = "lfj"; # ← change this to switch DEX

  # Pool to trade. Must match a key in DEX_REGISTRY[dex].pools in config.ts:
  #   pharaoh:  weth-wavax, wavax-usdc, savax-wavax
  #   lfj:      avax-usdc
  currentPool = "avax-usdc"; # ← change this to switch pools
in
{
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
      StateDirectory = "phar-liquidity-bot";
      WorkingDirectory = "%S/phar-liquidity-bot";
      Environment = [
        "DEX_NAME=${currentDex}"
        "POOL_NAME=${currentPool}"
      ];
      EnvironmentFile = envFile;
      # Wait for Avalanche RPC to be reachable before starting
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'for i in {1..12}; do if ${pkgs.iputils}/bin/ping -c 1 api.avax.network &>/dev/null; then exit 0; fi; sleep 5; done; exit 1'";
      ExecStart = "${lib.getExe botPkg} --mode=eoa";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}

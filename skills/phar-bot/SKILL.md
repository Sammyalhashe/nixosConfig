---
name: phar-bot
description: Manage the Phar Liquidity Rebalancing Bot on Avalanche.
metadata: {"clawdbot":{"emoji":"🤖"}}
---

# Phar Liquidity Bot

This skill allows you to manage the Phar Liquidity Bot located in `~/Projects/phar-liquidity-bot`. The bot manages a WETH.e/AVAX liquidity position on Pharaoh V3 (Avalanche).

## Core Commands

The bot is packaged as a Nix flake and can be run with arguments.

### 0. Withdraw Funds to Main Wallet 
Use this command to immediately send all WETH.e, USDC, PHAR, WAVAX, and most AVAX (keeping 0.1 buffer) from the Smart Account back to your main wallet. 

```bash 
nix run /home/salhashemi2/Projects/phar-liquidity-bot#withdraw 
``` 

### 1. Complete Rebalance (Sweep Funds)
Use this command to immediately withdraw all liquidity, wrap native AVAX (keeping 0.05 buffer), and redeploy 98% of all balances into a fresh centered position. Use this when adding new funds.

```bash
nix run /home/salhashemi2/Projects/phar-liquidity-bot# -- --complete-rebalance
```

### 2. Start Service (Monitoring Mode)
The bot usually runs as a systemd user service, checking the range every 5 minutes.

```bash
systemctl --user start phar-liquidity-bot
```

### 3. Stop Service
```bash
systemctl --user stop phar-liquidity-bot
```

### 4. Check Status & Logs
```bash
systemctl --user status phar-liquidity-bot
journalctl --user -u phar-liquidity-bot -n 50 --no-pager
```

## Bot Configuration
- **Smart Account:** `0x0cda565dcf71c5293De7C0Ba94a46dE4224a1602`
- **Pool:** WETH.e/AVAX (`0xff0855a9027f5f5c2bbacc4aac477afbeeefbea9`)
- **Gas Buffer:** Always maintain at least **0.5 AVAX** in the smart account for STF (SafeTransferFrom) operations.

## Maintenance Tasks
- **Low Gas Alert:** If AVAX balance < 0.5, alert the user.
- **Out of Range:** If the bot logs "OUT OF RANGE" repeatedly without rebalancing, check the Smart Account gas balance.
- **STF Reverts:** Usually caused by insufficient gas or incorrect Position Manager approvals.

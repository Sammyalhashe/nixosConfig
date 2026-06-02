#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python313 python313Packages.requests python313Packages.coinbase-advanced-py

import json
import logging
import os
import sys
import uuid

import requests
from coinbase.rest import RESTClient

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)

API_KEY_FILE = f"{os.getenv('HOME')}/hardware_maker_api_key.json"


def load_bot_config(config_path: str) -> tuple:
    """Loads target configurations from your unified SOPS JSON file."""
    with open(config_path, "r") as f:
        data = json.load(f)
    return data.get("addresses", {}), data.get("networks", {})


def get_primary_portfolio_uuid(client: RESTClient) -> str:
    """Locates the precise UUID for the 'Primary' portfolio."""
    portfolios = client.get_portfolios().to_dict().get("portfolios", [])
    logging.info(f"portfolios: {portfolios}")
    for p in portfolios:
        if p.get("name") == "Default":
            return p.get("uuid")
    raise ValueError("Portfolio named 'Primary' not found on this account.")


def main():
    if not os.path.exists(API_KEY_FILE):
        logging.error(f"Missing configuration profile at {API_KEY_FILE}")
        sys.exit(1)

    # Load addresses and target networks from our single SOPS file
    addresses, networks = load_bot_config(API_KEY_FILE)
    target_coins = list(addresses.keys())  # ['BTC', 'SOL', 'SUI', 'ETH', 'AVAX']

    client = RESTClient(key_file=API_KEY_FILE)

    try:
        # 1. Isolate the 'Primary' Portfolio
        primary_uuid = get_primary_portfolio_uuid(client)
        logging.info(f"Isolated 'Primary' Portfolio ID: {primary_uuid}")

        # 2. Extract accounts belonging exclusively to the 'Primary' portfolio
        all_accounts = client.get_accounts(limit=250).to_dict().get("accounts", [])
        primary_accounts = {
            a.get("currency"): a
            for a in all_accounts
            if a.get("retail_portfolio_id") == primary_uuid
        }

        # 3. Process each coin individually
        for coin in target_coins:
            try:
                if coin not in primary_accounts:
                    logging.warning(
                        f"Skipping {coin}: No active wallet found in 'Primary' portfolio."
                    )
                    continue

                account_data = primary_accounts[coin]
                account_id = account_data.get("uuid")

                # Fetch the actual liquid balance inside this exact portfolio
                available_balance = float(
                    account_data.get("available_balance", {}).get("value", 0.0)
                )

                if available_balance <= 0:
                    logging.info(f"Skipping {coin}: Balance is completely empty.")
                    continue

                # 4. Calculate exact 5% allocation for this specific coin
                target_withdrawal = available_balance * 0.02

                # Check for dust limits (Coinbase blocks transfers that round down to zero)
                if target_withdrawal < 0.00000001:
                    logging.warning(
                        f"Skipping {coin}: 5% calculation resulted in dust payload ({target_withdrawal})."
                    )
                    continue

                # Format safely to string to drop excessive float decimals
                withdrawal_amount_str = f"{target_withdrawal:.8f}".rstrip("0").rstrip(
                    "."
                )

                logging.info(
                    f"Processing sweep: 5% of {available_balance} {coin} = {withdrawal_amount_str} {coin}"
                )

                # 5. Execute Legacy v2 Send Request
                endpoint = f"/v2/accounts/{account_id}/transactions"
                payload = {
                    "type": "send",
                    "to": addresses[coin],
                    "amount": withdrawal_amount_str,
                    "currency": coin,
                    # "network": networks[coin],
                    "idem": str(
                        uuid.uuid4()
                    ),  # Prevent double-sends on network timeouts
                }

                logging.info(
                    f"🚀 Pushing {withdrawal_amount_str} {coin} to external wallet '{addresses[coin]}' on network '{networks[coin]}'..."
                )
                response = client.post(endpoint, data=payload)

                tx_id = response.get("data", {}).get("id", "Pending/Queued")
                logging.info(
                    f"✅ Successfully completed {coin} transaction. ID: {tx_id}"
                )
            except Exception as coin_error:
                logging.error(
                    f"Failed to process sweep for coin {coin}: {coin_error}"
                )

    except Exception as e:
        logging.error(f"System error encountered during sweep iteration: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()

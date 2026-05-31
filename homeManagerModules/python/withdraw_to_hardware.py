#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3 python3Packages.requests python3Packages.pyjwt python3Packages.cryptography python313Packages.coinbase-advanced-py

import json
import logging
import uuid
import os
import secrets
import time
import urllib.parse
from typing import Tuple

import jwt
import requests
from coinbase.rest import RESTClient
from cryptography.hazmat.primitives import serialization


def get_creds(api_key_file: str) -> Tuple[str, str]:
    with open(api_key_file, "r") as f:
        data = json.load(f)
    return data.get("name"), data.get("privateKey")


def _build_jwt(api_key_name, private_key_pem, service, uri):
    private_key = serialization.load_pem_private_key(
        private_key_pem.encode("utf-8"), password=None
    )
    jwt_payload = {
        "iss": "cdp",
        "nbf": int(time.time()),
        "exp": int(time.time()) + 120,
        "sub": api_key_name,
        "uri": f"{service} {uri}",
    }
    return jwt.encode(
        jwt_payload,
        private_key,
        algorithm="ES256",
        headers={"kid": api_key_name, "nonce": secrets.token_hex()},
    )


def request(self, method, path, body=None):
    try:
        api_key_name, private_key = self._get_credentials()
        host = "api.coinbase.com"
        path_for_jwt = urllib.parse.urlparse(path).path
        token = self._build_jwt(
            api_key_name, private_key, method, f"{host}{path_for_jwt}"
        )
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        }
        response = requests.request(
            method.upper(),
            f"https://{host}{path}",
            headers=headers,
            json=body,
            timeout=15,
        )
        response.raise_for_status()
        return response.json()
    except Exception as e:
        logging.error(f"Coinbase request failed: {e}")
    return None


def transfer_request(client: RESTClient) -> None:
    transfer_payload = {
        "type": "send",
        "to": "0xYourSelfCustodyWalletAddress",
        "amount": "0.01",
        "currency": "ETH",
        "network": "ethereum",
        "idem": str(uuid.uuid4()),
    }


def main():
    HOME = os.getenv("$HOME")
    if not HOME:
        print("$HOME not set, aborting...")
        return

    API_KEY_FILE = f"{HOME}/hardware_maker_api_key.json"

    client = RESTClient(key_file=API_KEY_FILE)


if __name__ == "__main__":
    main()

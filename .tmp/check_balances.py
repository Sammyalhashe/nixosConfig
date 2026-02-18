#!/usr/bin/env python3
import os
import json
import time
import jwt
import requests
import secrets
from cryptography.hazmat.primitives import serialization

API_JSON_FILE = "/home/salhashemi2/cdb_api_key.json"

def get_credentials():
    with open(API_JSON_FILE, 'r') as f: data = json.load(f)
    return data.get('name'), data.get('privateKey')

def build_jwt(api_key_name, private_key_pem, service, uri):
    private_key = serialization.load_pem_private_key(
        private_key_pem.encode('utf-8'),
        password=None
    )
    jwt_payload = {
        "iss": "cdp", "nbf": int(time.time()), "exp": int(time.time()) + 120,
        "sub": api_key_name, "uri": f"{service} {uri}"
    }
    return jwt.encode(jwt_payload, private_key, algorithm="ES256", headers={"kid": api_key_name, "nonce": secrets.token_hex()})

def coinbase_request(method, path):
    api_key_name, private_key = get_credentials()
    host = "api.coinbase.com"
    full_request_uri = f"https://{host}{path}"
    
    # Construction of JWT URI must exclude query params
    import urllib.parse
    path_for_jwt = urllib.parse.urlparse(path).path
    
    token = build_jwt(api_key_name, private_key, method, f"{host}{path_for_jwt}")
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    response = requests.request(method, full_request_uri, headers=headers)
    return response.json()

print("--- COINBASE BALANCES (PAGINATED) ---")
path = "/api/v3/brokerage/accounts"
while True:
    data = coinbase_request("GET", path)
    if 'accounts' in data:
        for acc in data['accounts']:
            val = float(acc['available_balance']['value'])
            if val > 0:
                print(f"{acc['currency']}: {val}")
        
        if data.get('has_next'):
            cursor = data.get('cursor')
            path = f"/api/v3/brokerage/accounts?cursor={cursor}"
        else:
            break
    else:
        print(data)
        break
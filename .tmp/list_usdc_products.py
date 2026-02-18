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
    private_key = serialization.load_pem_private_key(private_key_pem.encode('utf-8'), password=None)
    jwt_payload = {
        "iss": "cdp", "nbf": int(time.time()), "exp": int(time.time()) + 120,
        "sub": api_key_name, "uri": f"{service} {uri}"
    }
    return jwt.encode(jwt_payload, private_key, algorithm="ES256", headers={"kid": api_key_name, "nonce": secrets.token_hex()})

def coinbase_request(method, path):
    api_key_name, private_key = get_credentials()
    host = "api.coinbase.com"
    full_request_uri = f"https://{host}{path}"
    token = build_jwt(api_key_name, private_key, method, f"{host}{path}")
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    response = requests.request(method, full_request_uri, headers=headers)
    return response.json()

print("--- COINBASE USDC PRODUCTS ---")
data = coinbase_request("GET", "/api/v3/brokerage/products")
if 'products' in data:
    usdc_products = [p['product_id'] for p in data['products'] if 'USDC' in p['product_id']]
    print(usdc_products)
else:
    print(data)

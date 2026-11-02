"""Swap-only guard in front of @nearai/near-mcp: allowlisted tools, the agent's own
account only, and every swap posted to ntfy before it is forwarded."""

import json
import os
import shutil
import signal
import subprocess
import sys
import tempfile
import threading
import urllib.request

ALLOWED = {
    "account_view_account_summary",
    "search_near_fungible_tokens",
    "contract_view_functions",
    "contract_get_function_args",
    "contract_call_raw_function_as_read_only",
    "ref_finance_get_pools",
    "ref_finance_get_swap_estimate",
    "ref_finance_execute_swap",
}
NOTIFY = {"ref_finance_execute_swap"}

out_lock = threading.Lock()


def emit(msg):
    with out_lock:
        sys.stdout.write(json.dumps(msg) + "\n")
        sys.stdout.flush()


def refuse(msg, reason):
    emit({"jsonrpc": "2.0", "id": msg.get("id"),
          "result": {"content": [{"type": "text", "text": f"Refused by wallet guard: {reason}"}], "isError": True}})


def notify(title, body):
    req = urllib.request.Request(
        "https://ntfy.salh.xyz/wallets", data=body.encode(), method="POST",
        headers={"Authorization": "Bearer " + open(os.environ["NTFY_TOKEN_FILE"]).read().strip(),
                 "Title": title, "Tags": "currency_exchange"})
    urllib.request.urlopen(req, timeout=15).read()


def main():
    key = json.loads(open(os.environ["NEAR_KEYFILE"]).read())
    account = key["account_id"]
    # RAM-backed, and SIGTERM (how clients stop servers) still reaches the cleanup.
    keystore = tempfile.mkdtemp(prefix="near-keystore-", dir=os.environ.get("XDG_RUNTIME_DIR"))
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    try:
        os.makedirs(f"{keystore}/mainnet")
        path = f"{keystore}/mainnet/{account}.json"
        with open(os.open(path, os.O_WRONLY | os.O_CREAT, 0o600), "w") as f:
            json.dump(key, f)

        child = subprocess.Popen(
            [os.environ["NPX"], "--yes", "@nearai/near-mcp@0.0.35", "run", "--key-dir", keystore],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)

        def from_server():
            for line in child.stdout:
                try:
                    msg = json.loads(line)
                except ValueError:
                    continue
                tools = msg.get("result", {}).get("tools") if isinstance(msg.get("result"), dict) else None
                if tools is not None:
                    msg["result"]["tools"] = [t for t in tools if t["name"] in ALLOWED]
                emit(msg)
            # The server is gone; don't leave the client waiting on a dead pipe.
            shutil.rmtree(keystore, ignore_errors=True)
            os._exit(child.wait() or 1)

        threading.Thread(target=from_server, daemon=True).start()

        for line in sys.stdin:
            try:
                msg = json.loads(line)
            except ValueError:
                continue
            if msg.get("method") == "tools/call":
                name = msg["params"].get("name")
                args = msg["params"].get("arguments") or {}
                if name not in ALLOWED:
                    refuse(msg, f"{name} is not allowed")
                    continue
                if args.get("networkId", "mainnet") != "mainnet":
                    refuse(msg, "only mainnet is allowed")
                    continue
                for field in ("accountId", "signerAccountId"):
                    if field in args and args[field] != account:
                        refuse(msg, f"{field} must be the agent wallet {account}")
                        break
                else:
                    if name in NOTIFY:
                        try:
                            notify("NEAR swap requested", json.dumps(args, indent=1))
                        except Exception as err:
                            refuse(msg, f"could not notify ntfy ({err}), so not swapping")
                            continue
                    child.stdin.write(json.dumps(msg) + "\n")
                    child.stdin.flush()
                continue
            child.stdin.write(json.dumps(msg) + "\n")
            child.stdin.flush()
        child.terminate()
    finally:
        shutil.rmtree(keystore, ignore_errors=True)


if __name__ == "__main__":
    main()

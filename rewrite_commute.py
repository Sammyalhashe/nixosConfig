content = r"""#!/usr/bin/env python3
import os
import requests
from datetime import datetime

TELEGRAM_CHAT_ID = "8555669756"
STOP_NAME = "28 St"

def send_telegram_message(message_html):
    """Sends message via direct API call to avoid gateway conflicts."""
    token_file = "/run/secrets/telegram_bot_token"
    if not os.path.exists(token_file):
        print("Token file missing")
        return
    with open(token_file, "r") as f: token = f.read().strip()
    url = f"https://api.telegram.org/bot{token}/sendMessage"
    payload = {"chat_id": TELEGRAM_CHAT_ID, "text": message_html, "parse_mode": "HTML"}
    try:
        r = requests.post(url, json=payload, timeout=10)
        r.raise_for_status()
        print("Message sent successfully")
    except Exception as e:
        print(f"Failed to send: {e}")

def get_transit_data():
    try:
        alerts_url = "https://api-endpoint.mta.info/Dataservice/MTADatetimeService/gtfs-alerts"
        r_alerts = requests.get(alerts_url, timeout=10)
        status = "Good Service"
        if r_alerts.status_code == 200:
            if b"6 Train" in r_alerts.content or b"Lexington Av" in r_alerts.content:
                status = "Delays / Service Change reported"
        
        now = datetime.now().strftime("%H:%M")
        html = (
            f"🚆 <b>MTA Notifier: 6 Train</b> ({now})\n\n"
            f"<b>From:</b> {STOP_NAME} & Park Ave\n"
            f"<b>To:</b> Lexington Ave/53 St\n\n"
            f"⚠️ <b>Line Status:</b> {status}\n\n"
            f"<i>Note: Automated via systemd user timer.</i>"
        )
        return html
    except Exception as e:
        return f"⚠️ <b>Transit Notifier Error</b>\n{str(e)}"

if __name__ == "__main__":
    send_telegram_message(get_transit_data())
"""
with open("/home/salhashemi2/.openclaw/workspace/skills/transit-notifier/commute.py", "w") as f:
    f.write(content)

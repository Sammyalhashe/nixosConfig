import sys
import os

path = "/home/salhashemi2/trading-bot-flake/report_bot.py"
with open(path, "r") as f:
    content = f.read()

# 1. Update the parse_logs_for_signals function to scan for last 24H instead of just last run
new_parse_func = """def parse_logs_for_signals():
    \"\"\"Parses the log file for trade signals within the last 24 hours.\"\"\"
    if not os.path.exists(LOG_FILE):
        return []

    signals = []
    # Regex to find any signal line from the log
    signal_regex = re.compile(r"(\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}),\\d+ - INFO - SIGNAL (BUY|SELL): \\$?([\\d,.]+) (?:of )?([\\w-]+)")
    
    cutoff_time = datetime.now() - timedelta(hours=24)

    with open(LOG_FILE, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()

    for i, line in enumerate(lines):
        match = signal_regex.search(line)
        if match:
            ts_str, signal_type, amount_str, asset_pair = match.groups()
            try:
                dt = datetime.strptime(ts_str, "%Y-%m-%d %H:%M:%S")
                if dt < cutoff_time:
                    continue
            except:
                continue

            amount = float(amount_str.replace(",", ""))
            asset = asset_pair.split("-")[0]
            
            # Find the price for this asset just before the signal (look back 20 lines)
            price_at_signal = None
            for j in range(i - 1, max(0, i - 30), -1):
                if f"INFO - {asset}-USDC: Price=" in lines[j] or f"INFO - {asset}-USD: Price=" in lines[j]:
                    try:
                        price_str = lines[j].split('$')[-1].split(',')[0].replace(",", "")
                        # Try a cleaner split if that failed
                        if "MA" in price_str:
                             price_str = lines[j].split('Price=$')[-1].split(',')[0].replace(",", "")
                        
                        price_at_signal = float(price_str)
                        break
                    except:
                        continue
            
            if price_at_signal:
                signals.append({
                    "asset": asset,
                    "type": signal_type,
                    "amount": amount,
                    "price_at_signal": price_at_signal,
                    "timestamp": ts_str
                })
                
    return signals"""

# Find the start and end of the old function to replace it
import re
old_func_pattern = re.compile(r"def parse_logs_for_signals\(\):.*?return signals", re.DOTALL)
content = old_func_pattern.sub(new_parse_func, content)

with open(path, "w") as f:
    f.write(content)

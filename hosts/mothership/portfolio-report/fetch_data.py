"""Market context for the daily portfolio report, as source-tagged Markdown."""

import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from datetime import date, datetime, timedelta, timezone

TIMEOUT = 20
FRED_SERIES = {
    "FEDFUNDS": "Effective federal funds rate (%)",
    "CPIAUCSL": "CPI, all urban consumers (index)",
    "UNRATE": "Unemployment rate (%)",
    "DGS2": "2-year Treasury yield (%)",
    "DGS10": "10-year Treasury yield (%)",
    "T10Y2Y": "10y minus 2y Treasury spread (pp)",
    "BAMLH0A0HYM2": "US high-yield credit spread (%)",
    "VIXCLS": "VIX volatility index",
    "DTWEXBGS": "Broad US dollar index",
    "DCOILWTICO": "WTI crude oil ($/bbl)",
}
RSS_FEEDS = {
    "CoinDesk": "https://www.coindesk.com/arc/outboundfeeds/rss/",
    "The Block": "https://www.theblock.co/rss.xml",
    "CNBC Markets": "https://www.cnbc.com/id/10000664/device/rss/rss.html",
}


def read_secret(name):
    with open(os.environ[name]) as f:
        return f.read().strip()


def get_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": "portfolio-report/1.0"})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
        return json.load(resp)


def fred(key):
    lines = ["## Macro indicators [FRED]", ""]
    start = (date.today() - timedelta(days=400)).isoformat()
    for series, label in FRED_SERIES.items():
        query = urllib.parse.urlencode({
            "series_id": series, "api_key": key, "file_type": "json",
            "observation_start": start, "sort_order": "desc",
        })
        obs = [o for o in get_json(f"https://api.stlouisfed.org/fred/series/observations?{query}")["observations"]
               if o["value"] != "."]
        if not obs:
            continue
        latest, year_ago = obs[0], obs[-1]
        lines.append(f"- {label}: {latest['value']} on {latest['date']} "
                     f"(was {year_ago['value']} on {year_ago['date']})")
    return lines


def finnhub(key):
    lines = []
    for category in ("general", "crypto"):
        news = get_json(f"https://finnhub.io/api/v1/news?category={category}&token={key}")[:15]
        lines += ["", f"## {category.title()} market news [Finnhub]", ""]
        for item in news:
            when = datetime.fromtimestamp(item["datetime"], timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
            lines.append(f"- {when} | {item['source']}: {item['headline']}")
    today = date.today()
    try:
        cal = get_json(f"https://finnhub.io/api/v1/calendar/economic?from={today}"
                       f"&to={today + timedelta(days=7)}&token={key}")
        events = [e for e in cal.get("economicCalendar", []) if e.get("country") == "US"][:20]
        lines += ["", "## US economic calendar, next 7 days [Finnhub]", ""]
        lines += [f"- {e['time']} {e['event']} (impact: {e.get('impact', '?')})" for e in events]
    except urllib.error.HTTPError as err:
        lines += ["", f"(Economic calendar unavailable: HTTP {err.code})"]
    return lines


def fear_and_greed():
    data = get_json("https://api.alternative.me/fng/?limit=7")["data"]
    lines = ["", "## Crypto Fear & Greed Index, last 7 days [alternative.me]", ""]
    for d in data:
        day = datetime.fromtimestamp(int(d["timestamp"]), timezone.utc).date()
        lines.append(f"- {day}: {d['value']} ({d['value_classification']})")
    return lines


def rss():
    lines = []
    for name, url in RSS_FEEDS.items():
        req = urllib.request.Request(url, headers={"User-Agent": "portfolio-report/1.0"})
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            items = ET.parse(resp).getroot().iter("item")
        lines += ["", f"## Headlines [{name}]", ""]
        for item in list(items)[:8]:
            lines.append(f"- {item.findtext('pubDate', '').strip()} | {item.findtext('title', '').strip()}")
    return lines


def section(fn, *args):
    # One failing source must not sink the whole report.
    try:
        return fn(*args)
    except Exception as err:
        return ["", f"({fn.__name__} unavailable: {type(err).__name__}: {err})"]


def main():
    out = [f"# Market data collected {datetime.now(timezone.utc):%Y-%m-%d %H:%M UTC}", ""]
    out += section(fred, read_secret("FRED_API_KEY_FILE"))
    out += section(finnhub, read_secret("FINNHUB_API_KEY_FILE"))
    out += section(fear_and_greed)
    out += section(rss)
    sys.stdout.write("\n".join(out) + "\n")


if __name__ == "__main__":
    main()

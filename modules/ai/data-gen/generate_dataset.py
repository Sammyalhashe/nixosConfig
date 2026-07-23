#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "openai>=1.40",
#     "yfinance>=0.2.40",
#     "pandas>=2.0",
#     "requests>=2.31",
#     "tenacity>=8.2",
# ]
# ///
"""Generate a Phi-4 fine-tuning dataset for a financial/TA/crypto analyst.

Design principle (matches ../financial-llm.md): the *numbers* are real and are
handed to the model in the user turn (as if a tool already fetched them); the
teacher model only writes the *judgment/interpretation*. This trains reasoning &
style, not memorized figures, and keeps the data grounded (no hallucinated math).

Output: JSONL, one record per line, in conversational format:
    {"messages": [{"role": "system"...}, {"role": "user"...}, {"role": "assistant"...}]}
TRL's SFTTrainer consumes this directly and applies Phi-4's chat template for you.

Usage:
    # Free/local teacher (your litellm gateway -> local Qwen):
    ./generate_dataset.py --out train.jsonl

    # Real Claude as teacher (best quality) via Anthropic's OpenAI-compatible API:
    OPENAI_API_KEY=sk-ant-... ./generate_dataset.py \
        --base-url https://api.anthropic.com/v1/ --model claude-sonnet-5 --out train.jsonl

    # SEC filings require a contact User-Agent (SEC blocks empty UAs):
    SEC_USER_AGENT="Your Name you@example.com" ./generate_dataset.py --out train.jsonl
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time

import pandas as pd
import requests
import yfinance as yf
from openai import OpenAI
from tenacity import retry, stop_after_attempt, wait_exponential

SYSTEM = (
    "You are a rigorous financial analyst expert in technical analysis, trend "
    "following, company valuation, reading balance sheets, and crypto markets. "
    "Base every figure strictly on the data provided in the prompt; never invent "
    "numbers. Be concise, structured, and show your reasoning. This is not "
    "financial advice."
)

# Question templates per skill. {t} = ticker. The real data is appended as JSON.
TEMPLATES = {
    "trend": [
        "Analyze the current trend for {t} and judge whether this is a valid "
        "trend-following setup, using the indicator snapshot below.",
        "Is {t} overbought or oversold right now, and what do the moving averages "
        "and momentum imply for the next few weeks? Use the data below.",
    ],
    "valuation": [
        "Assess {t}'s balance-sheet health and leverage from the figures below. "
        "Compute the key ratios (current ratio, debt-to-equity) and interpret them.",
        "Give a quick fundamental read on {t} using the financials below "
        "(profitability, leverage, liquidity). Flag any red flags.",
    ],
    "crypto": [
        "Give a technical read on {t}: trend, momentum, and key levels, from the "
        "market snapshot below.",
        "Would you treat {t} as risk-on or risk-off right now based on the momentum "
        "and moving-average structure below? Explain.",
    ],
}


# --------------------------------------------------------------------------- #
# Market data + indicators (real numbers, computed locally with pandas)
# --------------------------------------------------------------------------- #
def ohlcv(ticker: str, period: str = "1y") -> pd.DataFrame:
    df = yf.Ticker(ticker).history(period=period, interval="1d")
    if df.empty:
        raise ValueError(f"no price data for {ticker}")
    return df


def _rsi(close: pd.Series, n: int = 14) -> float:
    delta = close.diff()
    gain = delta.clip(lower=0).rolling(n).mean()
    loss = (-delta.clip(upper=0)).rolling(n).mean()
    rs = gain / loss.replace(0, pd.NA)
    return float((100 - 100 / (1 + rs)).iloc[-1])


def indicators(df: pd.DataFrame) -> dict:
    close = df["Close"]
    ema12, ema26 = close.ewm(span=12).mean(), close.ewm(span=26).mean()
    macd = ema12 - ema26
    signal = macd.ewm(span=9).mean()
    last = float(close.iloc[-1])

    def sma(n: int):
        return round(float(close.rolling(n).mean().iloc[-1]), 2) if len(close) >= n else None

    sma50, sma200 = sma(50), sma(200)
    trend = "sideways"
    if sma50 and sma200:
        trend = "uptrend" if last > sma50 > sma200 else "downtrend" if last < sma50 < sma200 else "mixed"
    hi52, lo52 = float(close.tail(252).max()), float(close.tail(252).min())
    return {
        "price": round(last, 2),
        "sma20": sma(20), "sma50": sma50, "sma200": sma200,
        "rsi14": round(_rsi(close), 1),
        "macd": round(float(macd.iloc[-1]), 3),
        "macd_signal": round(float(signal.iloc[-1]), 3),
        "macd_hist": round(float((macd - signal).iloc[-1]), 3),
        "high_52w": round(hi52, 2), "low_52w": round(lo52, 2),
        "pct_from_52w_high": round((last / hi52 - 1) * 100, 1),
        "trend": trend,
    }


# --------------------------------------------------------------------------- #
# SEC EDGAR fundamentals (free structured XBRL facts)
# --------------------------------------------------------------------------- #
_CIK_CACHE: dict[str, str] | None = None
_GAAP = {
    "assets": "Assets",
    "liabilities": "Liabilities",
    "equity": "StockholdersEquity",
    "current_assets": "AssetsCurrent",
    "current_liabilities": "LiabilitiesCurrent",
    "revenue": "Revenues",
    "net_income": "NetIncomeLoss",
    "cash": "CashAndCashEquivalentsAtCarryingValue",
    "long_term_debt": "LongTermDebtNoncurrent",
}


def _sec_headers(ua: str) -> dict:
    return {"User-Agent": ua, "Accept-Encoding": "gzip, deflate"}


def _cik_for(ticker: str, ua: str) -> str | None:
    global _CIK_CACHE
    if _CIK_CACHE is None:
        r = requests.get("https://www.sec.gov/files/company_tickers.json",
                         headers=_sec_headers(ua), timeout=30)
        r.raise_for_status()
        _CIK_CACHE = {v["ticker"].upper(): f'{v["cik_str"]:010d}' for v in r.json().values()}
    return _CIK_CACHE.get(ticker.upper())


def fundamentals(ticker: str, ua: str) -> dict | None:
    """Latest annual (10-K) values for a handful of us-gaap concepts. Best-effort."""
    cik = _cik_for(ticker, ua)
    if not cik:
        return None
    r = requests.get(f"https://data.sec.gov/api/xbrl/companyfacts/CIK{cik}.json",
                     headers=_sec_headers(ua), timeout=30)
    r.raise_for_status()
    facts = r.json().get("facts", {}).get("us-gaap", {})
    out: dict = {}
    for label, concept in _GAAP.items():
        units = facts.get(concept, {}).get("units", {}).get("USD", [])
        annual = [u for u in units if u.get("form") == "10-K" and u.get("fp") == "FY" and "val" in u]
        if annual:
            out[label] = annual[-1]["val"]  # most recent annual filing
    return out or None


# --------------------------------------------------------------------------- #
# Teacher model (any OpenAI-compatible endpoint: litellm, Anthropic, OpenAI)
# --------------------------------------------------------------------------- #
@retry(stop=stop_after_attempt(4), wait=wait_exponential(min=2, max=30))
def ask_teacher(client: OpenAI, model: str, user: str) -> str:
    resp = client.chat.completions.create(
        model=model,
        messages=[{"role": "system", "content": SYSTEM}, {"role": "user", "content": user}],
        temperature=0.5,
        max_tokens=900,
    )
    return resp.choices[0].message.content.strip()


def record(user: str, assistant: str) -> dict:
    return {"messages": [
        {"role": "system", "content": SYSTEM},
        {"role": "user", "content": user},
        {"role": "assistant", "content": assistant},
    ]}


def build(client, model, ticker, kind, data, i) -> dict:
    tmpl = TEMPLATES[kind][i % len(TEMPLATES[kind])]
    user = f"{tmpl.format(t=ticker)}\n\n```json\n{json.dumps(data, indent=2)}\n```"
    return record(user, ask_teacher(client, model, user))


# --------------------------------------------------------------------------- #
def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--out", default="train.jsonl")
    p.add_argument("--equities", default="AAPL,MSFT,NVDA,JPM,KO,XOM")
    p.add_argument("--crypto", default="BTC-USD,ETH-USD,SOL-USD")
    p.add_argument("--per-ticker", type=int, default=2, help="examples per skill per ticker")
    p.add_argument("--base-url", default=os.environ.get("OPENAI_BASE_URL", "http://127.0.0.1:4000/v1"))
    p.add_argument("--model", default=os.environ.get("TEACHER_MODEL", "qwen3.6"))
    p.add_argument("--api-key", default=os.environ.get("OPENAI_API_KEY", "none"))
    p.add_argument("--sec-ua", default=os.environ.get("SEC_USER_AGENT", ""))
    p.add_argument("--sleep", type=float, default=0.5, help="seconds between teacher calls")
    args = p.parse_args()

    client = OpenAI(base_url=args.base_url, api_key=args.api_key)
    equities = [t.strip() for t in args.equities.split(",") if t.strip()]
    crypto = [t.strip() for t in args.crypto.split(",") if t.strip()]
    n = 0

    print(f"teacher: {args.model} @ {args.base_url}", file=sys.stderr)
    if not args.sec_ua:
        print("warning: no SEC User-Agent set; skipping valuation examples "
              "(set SEC_USER_AGENT='Name you@email' to enable)", file=sys.stderr)

    with open(args.out, "w") as f:
        for ticker in equities:
            try:
                ind = indicators(ohlcv(ticker))
            except Exception as e:  # noqa: BLE001 - skip bad tickers, keep going
                print(f"skip {ticker} (prices): {e}", file=sys.stderr)
                continue
            for i in range(args.per_ticker):
                for kind, payload in (("trend", ind),):
                    try:
                        f.write(json.dumps(build(client, args.model, ticker, kind, payload, i)) + "\n")
                        f.flush(); n += 1; time.sleep(args.sleep)
                    except Exception as e:  # noqa: BLE001
                        print(f"skip {ticker}/{kind}: {e}", file=sys.stderr)
            if args.sec_ua:
                try:
                    fund = fundamentals(ticker, args.sec_ua)
                    if fund:
                        for i in range(args.per_ticker):
                            f.write(json.dumps(build(client, args.model, ticker, "valuation", fund, i)) + "\n")
                            f.flush(); n += 1; time.sleep(args.sleep)
                except Exception as e:  # noqa: BLE001
                    print(f"skip {ticker}/valuation: {e}", file=sys.stderr)

        for ticker in crypto:
            try:
                ind = indicators(ohlcv(ticker))
            except Exception as e:  # noqa: BLE001
                print(f"skip {ticker} (prices): {e}", file=sys.stderr)
                continue
            for i in range(args.per_ticker):
                try:
                    f.write(json.dumps(build(client, args.model, ticker, "crypto", ind, i)) + "\n")
                    f.flush(); n += 1; time.sleep(args.sleep)
                except Exception as e:  # noqa: BLE001
                    print(f"skip {ticker}/crypto: {e}", file=sys.stderr)

    print(f"wrote {n} examples -> {args.out}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

# Financial LLM — data generation kit

Generates a grounded fine-tuning dataset for the Phi-4-mini financial analyst
(see [`../financial-llm.md`](../financial-llm.md)). It pulls **real** market data
(yfinance) and **real** fundamentals (SEC EDGAR XBRL), then uses a **teacher
model** to write the analysis. The numbers live in the prompt; the teacher only
supplies judgment — so the training targets are grounded, not hallucinated.

Output is conversational JSONL (`{"messages": [...]}`) that TRL's `SFTTrainer`
consumes directly — no manual `<|end|>` tokens, the trainer applies Phi-4's
chat template for you.

## Prerequisites

- `uv` (already on `mothership`). The script is self-contained — `uv run`
  installs its deps from the inline header automatically.
- Network access to `query1.finance.yahoo.com` (prices) and `data.sec.gov`
  (fundamentals). Behind a proxy, export `HTTPS_PROXY`.
- A **teacher endpoint** (below).

## Choosing the teacher

The teacher is any OpenAI-compatible endpoint — configurable, no code changes:

| Teacher | How | Notes |
|---|---|---|
| **Local Qwen** (default) | nothing — defaults to `http://127.0.0.1:4000/v1`, model `qwen3.6` | Free, private, lower quality. Your `litellm` gateway. |
| **Claude** (best) | `--base-url https://api.anthropic.com/v1/ --model claude-sonnet-5` + `OPENAI_API_KEY=sk-ant-…` | Anthropic's OpenAI-compatible API. Highest-quality targets. |
| **Claude via gateway** | add an `anthropic/…` route to `litellm-config.yaml`, then use its `model_name` | Keeps everything behind `:4000`. |

> ⚠️ Your `litellm-config.yaml` currently maps `opus`/`sonnet`/`haiku` to **local
> Qwen**, not Claude. To distill from real Claude, use the Anthropic API directly
> or add a genuine Anthropic route to the gateway.
>
> ⚠️ Anthropic's terms restrict using Claude outputs to train a *competing*
> model/service. A personal, non-redistributed finance model is the ordinary
> distillation case; don't turn the result into a competing commercial LLM.

## Run

```bash
cd modules/ai/data-gen

# Free local teacher, prices only (quickest smoke test):
./generate_dataset.py --out train.jsonl --equities AAPL,MSFT --crypto BTC-USD --per-ticker 1

# Full run with fundamentals (SEC requires a contact UA) + Claude teacher:
SEC_USER_AGENT="Sammy Al Hashemi you@email.com" OPENAI_API_KEY=sk-ant-... \
  ./generate_dataset.py --base-url https://api.anthropic.com/v1/ --model claude-sonnet-5 \
  --out train.jsonl --per-ticker 3
```

Key flags: `--equities`, `--crypto` (comma lists), `--per-ticker` (examples per
skill per ticker), `--model`, `--base-url`, `--sleep` (rate limit). Writes
incrementally and skips bad tickers, so a mid-run failure keeps partial output.

## Output → training

Each line is one chat example:

```json
{"messages": [
  {"role": "system", "content": "You are a rigorous financial analyst..."},
  {"role": "user", "content": "Analyze the current trend for AAPL...\n```json\n{...real indicators...}\n```"},
  {"role": "assistant", "content": "<teacher's grounded analysis>"}
]}
```

Feed `train.jsonl` straight into the TRL `SFTTrainer` snippet in
[`../financial-llm.md`](../financial-llm.md) (`load_dataset("json", ...)`).

## Scaling up (after the first run works)

- **More coverage:** expand `--equities`/`--crypto` (S&P sectors, top-50 coins)
  and raise `--per-ticker`. Aim for ~1–5k clean examples for a first model.
- **Diversity:** add question templates in `TEMPLATES` (options analysis,
  sector comparison, earnings reaction, on-chain metrics).
- **Quality gate:** hold out a test split; optionally add an LLM-as-judge pass
  to drop weak examples before training.
- **Tool-call variant (v2):** to train function-calling instead of inline
  interpretation, emit an assistant `tool_calls` turn + a `tool` result turn.
  The current kit trains the interpretation half (numbers provided in-context),
  which is the higher-value behavior to start with.

## Limits

- yfinance/EDGAR are rate-limited and occasionally flaky — the script tolerates
  gaps. EDGAR concept coverage varies by company (some ratios may be absent).
- The teacher's quality caps the student's — a stronger teacher = better dataset.
- Grounded ≠ correct: spot-check a sample of outputs before you train on 5k of them.

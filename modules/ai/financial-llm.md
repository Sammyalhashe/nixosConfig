# Custom Financial LLM — Fine-tuning Phi-4-mini on Strix Halo (`mothership`)

A practical, no-fluff plan for building a domain expert model for **technical analysis, trend
following, company valuation, balance-sheet reading, and crypto**, running on the existing
`mothership` (AMD Strix Halo / Ryzen AI Max 395, gfx1151, 128 GB unified memory) ROCm stack.

## TL;DR

- **Base model:** `microsoft/Phi-4-mini-instruct` (3.8B, 128K ctx, MIT license). Good quant/reasoning
  baseline at a size that fine-tunes on a single GPU and serves fast locally.
- **Method:** LoRA/QLoRA fine-tune on a curated, mostly *synthetic* domain dataset, then merge →
  convert to GGUF → serve on `mothership` via llama.cpp (same pattern as `gemma.nix`).
- **Where to train:** For a one-off ~4B fine-tune, **renting an NVIDIA GPU (~$0.35–$9/run) is the
  pragmatic path** — CUDA is still the frictionless route. Local training on Strix Halo *now works*
  (ROCm 7.x supports gfx1151, bitsandbytes ships gfx1151 wheels, Unsloth added AMD), but the reliable
  local variant is **bf16 LoRA**, not 4-bit QLoRA, and it carries a real setup tax.
- **Do NOT make the network do arithmetic.** Valuation math, indicator calc, and live prices come
  from **tool calls** (Python/APIs). The model decides *what* to compute and interprets results.

## Getting started (do this first)

Order matters — **data before GPU**. GPU rental is billed hourly; don't rent one to
"figure things out." All the fiddly parts are free and local; the paid run is short.

1. **Build the dataset (local, free) — nothing proceeds without it.** Datasets are
   *built, not found*: there's no off-the-shelf "TA + valuation + crypto" set, so you
   generate them (distillation from a teacher, grounded in real market data). Use the kit:
   ```bash
   cd modules/ai/data-gen
   # free/local teacher (your litellm gateway -> Qwen), quick smoke test:
   ./generate_dataset.py --out train.jsonl --equities AAPL,MSFT --crypto BTC-USD --per-ticker 1
   ```
   Eyeball `train.jsonl`. If it looks good, rerun with your full ticker list,
   `SEC_USER_AGENT="Name you@email"` set, and **Claude as the teacher** for higher-quality
   targets:
   ```bash
   OPENAI_API_KEY=sk-ant-... ./generate_dataset.py \
     --base-url https://api.anthropic.com/v1/ --model claude-sonnet-5 \
     --out train.jsonl --per-ticker 3
   ```
   Details/teacher options: [`data-gen/README.md`](data-gen/README.md). Target ~1–5k clean examples.
   (Note: your gateway's `opus`/`sonnet` aliases route to local Qwen, *not* Claude — use the
   Anthropic base-url above, or add a real `anthropic/…` route to `litellm-config.yaml`.)
2. **First training run — free.** Learn the mechanics at $0 on an **Unsloth Phi-4 Colab
   notebook** (free T4 fits a 3.8B QLoRA). Paste `train.jsonl`, run, download the adapter.
   This validates your data format before you pay for anything.
3. **Real run — cheap.** For scale/quality, rent an **RTX 4090 on [RunPod](https://runpod.io)**
   (~$0.35–0.69/hr, PyTorch template) or just keep using Colab. Same TRL/PEFT script (below),
   `target_modules="all-linear"`. ~1–6 GPU-hours.
4. **Merge → GGUF → serve locally** on `mothership` (Path A step 3 + Serving section below).

## The right architecture: fine-tune for judgment, tools for facts

The model should be trained to **reason and route**, not to memorize numbers or do math:

| Capability | How to handle |
|---|---|
| Balance-sheet / DCF math, ratios | Tool call → Python (`pandas`, `numpy`); model interprets output |
| Live prices, OHLCV, order books | Tool call → market/crypto API or RPC node |
| TA indicators (RSI, MACD, MAs) | Tool call → `pandas-ta`/`ta-lib`; model reads the values |
| Judgment: "is this trend intact?", "is this balance sheet healthy?" | **Fine-tuned weights** (this is what you train) |
| SEC filing / 10-K narrative comprehension | Fine-tuned weights + RAG over the filing text |

So the fine-tune teaches **style, domain vocabulary, structured output, and reasoning patterns** —
and it emits JSON tool calls for anything factual/numeric. This avoids the #1 failure mode of small
financial models (confident wrong numbers).

## Tools you need

- **Training:** Python (via `uv`), `transformers`, `peft`, `trl`, `datasets`, `accelerate`; plus
  either `unsloth` (turnkey) or `bitsandbytes` (for 4-bit). `torch` (ROCm build on `mothership`,
  CUDA build in the cloud).
- **Data:** a frontier "teacher" model (API) for synthetic data generation + distillation; `pandas`
  for XBRL/CSV wrangling; a PII scrubber if you ingest anything private.
- **Serving (already on `mothership`):** `llama.cpp` (ROCm/Vulkan), the `model-downloader` +
  `/var/lib/llama-cpp-models`, `litellm-uv` gateway (:4000), Open WebUI (:8080).
- **Inspection:** `amdgpu_top`, `rocminfo`, `nvtop` (already installed on `mothership`).

## Base model: Phi-4-mini specifics & gotchas

- 3.8B params, 128K context, **MIT** — commercially usable. Architecture is `phi3`
  (`Phi3ForCausalLM`), so it's first-class in `transformers`/`peft`. Microsoft ships a
  `sample_finetune.py` (TRL `SFTTrainer` + PEFT LoRA).
- **Fused layers gotcha:** Phi-3/4 fuses attention into `qkv_proj` and MLP into `gate_up_proj`.
  Llama-style `target_modules=["q_proj","v_proj",...]` will **silently match nothing**. Use
  `target_modules="all-linear"` (what Microsoft uses) or explicitly
  `["qkv_proj","o_proj","gate_up_proj","down_proj"]`.
- **Chat template:** `<|system|>…<|end|><|user|>…<|end|><|assistant|>`. Getting `<|end|>` right in
  your training data is the common pitfall — use the tokenizer's `apply_chat_template`.
- LoRA starting point: `r=16, alpha=32, dropout=0.05`, `trust_remote_code=True`.

## Data pipeline (this is 80% of the work)

Quality beats quantity — a clean 5k examples beats a noisy 50k. Format everything as **JSONL** chat
records that use the Phi-4 template.

1. **Valuation / accounting** — turn raw XBRL/SEC financials into instruction→response pairs that
   trace explicit identities (`Assets = Liabilities + Equity`) and ratio derivations (EV/EBITDA,
   D/E, FCF conversion). Where a number is computed, the "response" should be a **tool call**, and a
   follow-up turn interprets the returned value.
2. **Technical / crypto** — represent time-series as compact structured text (JSON snapshots of MAs,
   RSI/MACD, volume profile, liquidity/order-book depth) paired with risk-managed setups and a
   written rationale. Again: indicators via tool call, judgment in the text.
3. **Distillation** — have a frontier teacher generate step-by-step reasoning chains for balance-sheet
   reconciliations, 10-K/10-Q analysis, and multi-factor market assessments; that's your SFT corpus.
4. **Synthetic edge cases** — stressed balance sheets, sudden volatility, anomalous token velocity,
   accounting-fraud red flags — so the model generalizes beyond happy paths.
5. **Hygiene** — one format, strip PII, balance topics (don't let 90% be one sector), hold out a test
   split before you train.

## Path A (recommended for the first run): train in the cloud, serve locally

Cheapest and least fiddly for a one-off. A 3.8B QLoRA run is ~1–6 GPU-hours.

1. Rent a GPU (RunPod/Vast; RTX 4090 24 GB is plenty, ~$0.35–$0.69/hr; A100 if you want headroom).
2. Fine-tune with **Unsloth** (fastest) or **TRL + PEFT** (most standard). QLoRA is fine on CUDA.
3. Download the LoRA adapter, then on `mothership`:
   - Merge: `PeftModel.from_pretrained(base, adapter).merge_and_unload()` → save merged HF model.
   - Convert: `python llama.cpp/convert_hf_to_gguf.py <merged_dir> --outfile fin.gguf`.
   - Quantize: `llama-quantize fin.gguf fin-Q4_K_M.gguf Q4_K_M` (or `Q8_0` for max quality).
   - Drop it in `/var/lib/llama-cpp-models/` and add a service (below).

## Path B (all-local on `mothership`): bf16 LoRA on ROCm

Viable today; use it if keeping data local is the point or you want to learn the stack. Prefer
**bf16 LoRA over 4-bit QLoRA** here — QLoRA on the unified-memory iGPU is slow/finicky, and a 3.8B
LoRA only needs tens of GB, which this box has in abundance.

**Environment (use `uv`, don't pollute the Nix system Python):**

```bash
mkdir -p ~/ml/fin-llm && cd ~/ml/fin-llm
uv venv --python 3.13 && source .venv/bin/activate
# ROCm PyTorch (match the system ROCm 7.x). Use AMD's ROCm index or TheRock nightlies for gfx1151:
uv pip install --index-url https://download.pytorch.org/whl/rocm6.2 torch   # adjust to current ROCm
uv pip install transformers peft trl datasets accelerate
# Optional turnkey path:  uv pip install unsloth   (AMD/Strix Halo supported as of 2026)
# Optional 4-bit:         gfx1151 bitsandbytes wheels via TheRock / bitsandbytes>=0.49
```

**Notes specific to this box (already configured in `hosts/mothership/configuration.nix`):**

- gfx1151 is a native ROCm target now — the `HSA_OVERRIDE_GFX_VERSION=11.5.1` env is already set and
  is the correct value for Strix Halo (the old `11.0.0` override is obsolete and will fail with
  `no matching kernel image`). Some prerelease torch wheels still want it set — it already is.
- Kernel params already tune unified memory (`amd_iommu=off`, `ttm.pages_limit`, `amdgpu.gartsize`).
  For training you may hit the GPU memory fraction ceiling — cap it (`PYTORCH_HIP_ALLOC_CONF` /
  `set_per_process_memory_fraction(0.8)`) and run **eval out-of-process** to avoid OOM-killer stalls.
- Watch memory live with `amdgpu_top` while the first run warms up.

**Minimal LoRA train (TRL), same for cloud or local:**

```python
from trl import SFTTrainer, SFTConfig
from peft import LoraConfig
from transformers import AutoModelForCausalLM, AutoTokenizer
from datasets import load_dataset

m = "microsoft/Phi-4-mini-instruct"
tok = AutoTokenizer.from_pretrained(m, trust_remote_code=True)
model = AutoModelForCausalLM.from_pretrained(m, torch_dtype="bfloat16", trust_remote_code=True)
ds = load_dataset("json", data_files="train.jsonl")["train"]   # chat-format records

peft_cfg = LoraConfig(r=16, lora_alpha=32, lora_dropout=0.05,
                      target_modules="all-linear", task_type="CAUSAL_LM")
trainer = SFTTrainer(model=model, train_dataset=ds, peft_config=peft_cfg,
                     args=SFTConfig(output_dir="out", num_train_epochs=1,
                                    per_device_train_batch_size=1,
                                    gradient_accumulation_steps=16, bf16=True,
                                    learning_rate=2e-4, logging_steps=10))
trainer.train(); trainer.save_model("out/adapter")
```

## Serving the fine-tuned model (fits your existing pattern)

Add a service modeled on `modules/ai/llm-services/gemma.nix` — same ROCm llama.cpp override
(`useRocm`, `-DAMDGPU_TARGETS=gfx1151`, `-DGGML_HIP_NO_VMM=ON`), `--no-mmap`, `--n-gpu-layers 999`,
a new port, and point `--model` at your `fin-Q4_K_M.gguf`. Then:

- register the download in the `model-downloader` service (or just copy the file into
  `/var/lib/llama-cpp-models/`),
- add the endpoint to `litellm-uv` (:4000) and to Open WebUI's `OPENAI_API_BASE_URLS`,
- give it the tool/function-calling schemas for market data + the Python valuation/TA runtime.

## Evaluation (don't skip — SLMs have less margin)

- **Deterministic checks** for anything numeric: assert accounting identities hold, ratios match a
  reference `pandas` implementation, tool calls are well-formed JSON.
- **Backtest** TA/trend outputs against historical data — does the signal actually have edge?
- **LLM-as-judge** for qualitative write-ups (valuation theses, filing summaries) with a domain rubric.
- **Side-by-side vs base Phi-4-mini** to prove the fine-tune actually helped.

## Honest limits

- SLMs struggle with long multi-step reasoning over huge contexts and broad cross-domain
  generalization. Keep the scope tight (these five finance skills) and lean on tools + RAG.
- **Never let the model free-hand arithmetic or quote live prices from memory** — always tool-call.
- Plan for **drift**: markets, tickers, and filings change. Budget a quarterly retrain from freshly
  collected production data.
- Not financial advice; validate before trusting any output with real capital.

## References

- Phi-4-mini: https://huggingface.co/microsoft/Phi-4-mini-instruct · finetune sample:
  `.../raw/main/sample_finetune.py` · report: https://arxiv.org/abs/2503.01743
- ROCm gfx1151 status: https://github.com/ROCm/ROCm/issues/6348 ·
  https://rocm.docs.amd.com/en/latest/compatibility/compatibility-matrix.html ·
  TheRock: https://github.com/ROCm/TheRock/blob/main/RELEASES.md
- bitsandbytes ROCm/gfx1151: https://huggingface.co/docs/bitsandbytes/main/en/installation ·
  https://github.com/bitsandbytes-foundation/bitsandbytes/pull/1822
- Unsloth on AMD: https://unsloth.ai/docs/basics/amd
- Strix Halo fine-tune field guide: https://github.com/h34v3nzc0dex/strix-halo-llm-finetune-guide ·
  full/LoRA/QLoRA footprints: https://community.frame.work/t/finetuning-llms-on-strix-halo-full-lora-and-qlora-on-gemma-3-qwen-3-and-gpt-oss-20b/76986
- Strix Halo inference/toolboxes: https://github.com/kyuz0/amd-strix-halo-toolboxes ·
  llama.cpp Vulkan vs ROCm: https://github.com/ggml-org/llama.cpp/discussions/20856 ·
  Lemonade: https://github.com/lemonade-sdk/lemonade

{
  ...
}:
{
  # Candidate replacement for qwen3-8-flash-next: a plain small-active MoE
  # (35B total, 3B active) with no n-gram embedding tables. Benchmarked on
  # Strix Halo at ~45-51 tok/s generation and ~1050 tok/s prefill (kyuz0's
  # toolboxes, 2026-05), and 66% on SWE-bench-Verified-Mini via pi (kyuz0's
  # pi-bench, 2026-06) -- against ~15 tok/s from Flash-Next here.
  #
  # MEMORY: UD-Q8_K_XL is 36.4 GiB, so this leaves ~50 GB that Flash-Next ate,
  # which is what lets it share the box with the bitcoind/kaspad/lnd nodes.
  # That headroom is also why ctxSize follows the model card's advice of at
  # least 128K to preserve thinking.
  services.llm-services.models.qwen3-6-35b-a3b = {
    description = "Qwen3.6-35B-A3B";
    role = "coding-agent";
    port = 8015;

    hfRepo = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF";
    hfFile = "Qwen3.6-35B-A3B-UD-Q8_K_XL.gguf";

    ctxSize = 131072;
    threads = 8;
    kvCacheType = "q8_0";
    batchSize = 4096;
    ubatchSize = 512;

    # Qwen's tool-call syntax is only parsed into OpenAI-shaped `tool_calls`
    # when the model's own chat template is used.
    jinja = true;

    extraFlags = [
      # Qwen's template (HF Qwen/Qwen3.6-35B-A3B @ 995ad96) with the same
      # one-line change as qwen3-8-flash-next.jinja: a system message after the
      # first is rendered as its own turn instead of raising.
      "--chat-template-file ${./qwen3-6-35b-a3b.jinja}"
    ];

    # Same split as qwen3.8: thinking routed to message.reasoning_content so it
    # never corrupts tool-call parsing.
    reasoning = "auto";
    reasoningFormat = "deepseek";

    # Model card, thinking mode for general tasks -- the all-round profile,
    # since this serves Hermes as well as coding harnesses.
    sampling = {
      temp = 1.0;
      topP = 0.95;
      topK = 20;
      minP = 0.0;
      presencePenalty = 1.5;
    };

    aliases = {
      "qwen3.6" = { };
      "qwen3.6-fast".extra_body.chat_template_kwargs.enable_thinking = false;
    };
  };
}

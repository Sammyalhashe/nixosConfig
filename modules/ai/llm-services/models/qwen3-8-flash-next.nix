{
  ...
}:
{
  # Coding tier: 125B total but only 6B active per token (512 experts, 10 routed
  # + 1 shared). Strix Halo is memory-bandwidth-bound, not capacity-bound, so an
  # MoE this shape runs at small-model speed while the 128 GB holds a model that
  # would never fit on a discrete GPU.
  #
  # MEMORY: the GGUF stores ~177B weights (125B + ~51B n-gram embeddings), so it
  # is much larger than the parameter count suggests. UD-Q4_K_XL is 111 GB and
  # does not leave room for the OS; UD-IQ4_XS is 93.7 GB (~87 GiB), which clears
  # roughly 25 GiB once qwen-flash and the OS are accounted for. ctxSize is held
  # at 64k rather than the native 256k for the same reason -- the KV cache is
  # real memory. Raise it only after observing headroom with `free -g`.
  services.llm-services.models.qwen3-8-flash-next = {
    description = "Qwen3.8-Flash-Next";
    role = "coding-agent";
    port = 8014;

    # First shard of a 3-way split; llama-server reads split.count and fetches
    # the rest itself.
    hfRepo = "unsloth/Qwen3.8-Flash-Next-GGUF";
    hfFile = "UD-IQ4_XS/Qwen3.8-Flash-Next-UD-IQ4_XS-00001-of-00003.gguf";

    ctxSize = 65536;
    threads = 8;
    kvCacheType = "q8_0";
    batchSize = 4096;
    ubatchSize = 512;

    # Qwen's tool-call syntax is only parsed into OpenAI-shaped `tool_calls`
    # when the model's own chat template is used.
    jinja = true;

    # Keep thinking, but route it to message.reasoning_content so it never
    # lands in message.content and corrupts tool-call parsing in an agent
    # harness. This is what makes one endpoint safe for both Open WebUI chat
    # and Claude Code / pi.
    reasoning = "auto";
    reasoningFormat = "deepseek";

    # Model card, thinking mode. No min-p: that was a Hermes tool-use
    # workaround, not a Qwen setting.
    sampling = {
      temp = 1.0;
      topP = 0.95;
      topK = 20;
      presencePenalty = 0.0;
    };

    aliases = {
      # Reasoning on -- the default, best for interactive coding.
      "qwen3.8" = { };
      # Same weights, thinking suppressed per-request. For agent loops where
      # many short tool turns make the reasoning tax compound.
      "qwen3.8-fast".extra_body.chat_template_kwargs.enable_thinking = false;
    };
  };
}

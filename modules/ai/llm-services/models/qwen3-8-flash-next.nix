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
  # roughly 25 GiB once the OS is accounted for. ctxSize is held
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
    # f16 over q8_0: +8% generation at 16k depth, +15% at 32k (llama-bench), paid
    # for with the memory freed by no longer running qwen-flash alongside.
    kvCacheType = "f16";
    batchSize = 4096;
    # llama-bench on mothership: 2048 prefills 11-15% faster than 512 at 0-32k depth.
    ubatchSize = 2048;

    # Qwen's tool-call syntax is only parsed into OpenAI-shaped `tool_calls`
    # when the model's own chat template is used.
    jinja = true;

    extraFlags = [
      # Read the ~28 GB n-gram embedding rows on demand via the page cache: frees
      # ~26 GB of RAM for <2% generation cost (llama-bench, 2026-10-14).
      "--lazy-mode on"

      # Qwen's template (HF Qwen/Qwen3.8-Flash-Next @ de4b8e4) with one change:
      # a system message after the first is rendered as its own turn instead of
      # raising "System message must be at the beginning." Claude Code injects
      # those mid-conversation, and neither LiteLLM (PR #38503, unmerged) nor
      # llama.cpp (issue #27367, closed as template behaviour) normalizes them.
      "--chat-template-file ${./qwen3-8-flash-next.jinja}"

      # --hf-repo auto-loads the vision projector; this model only serves text agents.
      "--no-mmproj"

      # Multi-token prediction: 2.0x generation on code, 1.5x on prose, same output.
      # With --hf-repo, llama-server fetches the repo's MTP head into its own cache.
      "--spec-type draft-mtp"
    ];

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

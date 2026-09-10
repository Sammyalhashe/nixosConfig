{
  ...
}:
{
  # Utility tier: small, always-resident, cheap to keep alongside a large model.
  # Backs the hermes-agent auxiliary tasks (compression, web_extract,
  # title_generation), which is why the OpenAI-compatible aliases point here --
  # they are the cheap default for anything that is not real work.
  services.llm-services.models.qwen-flash = {
    description = "Qwen Flash";
    role = "utility";
    port = 8011;

    hfRepo = "bartowski/Qwen2.5-7B-Instruct-GGUF";
    hfFile = "Qwen2.5-7B-Instruct-Q8_0.gguf";
    modelPath = "/var/lib/llama-cpp-models/qwen2.5-7b-instruct-q8_0.gguf";

    ctxSize = 32768;
    threads = 8;

    aliases = {
      "qwen-flash" = { };
      "gpt-3.5-turbo" = { };
      "gpt-4o-mini" = { };
    };
  };
}

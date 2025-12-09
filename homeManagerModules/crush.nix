{
  config,
  pkgs,
  stdenv,
  ...
}:
{
  # Write the config file as JSON
  xdg.configFile."crush/crush.json".text = builtins.toJSON {
    "$schema" = "https://charm.land/crush.json";
    providers = {
        google = {
            name = "Google";
            type = "google";
            api_key = "AIzaSyAGKZBK8YYige6p8bn2hHTw8sZampcf-v0";
            models = [
              {
                name = "Gemini 2.0 Flash";
                base_url = "https://generativelanguage.googleapis.com/v1beta";
                id = "gemini-2.0-flash-exp";
                type = "openai-compat";
                context_window = 1048576;
                default_max_tokens = 8192;
              }
            ];
      };
      ollama = {
        name = "Ollama";
        base_url = "http://localhost:11434/v1";
        type = "openai-compat";
        models = [
          {
            name = "Qwen 3 8B";
            id = "qwen3:8b";
            context_window = 128000;
            default_max_tokens = 8192;
          }
          {
            name = "DeepSeek Coder V2 16B";
            id = "deepseek-coder-v2:16b";
            context_window = 16384;
            default_max_tokens = 4096;
          }
        ];
      };
    };
    options = {
      disable_provider_auto_update = true;
      debug = false;
    };
  };
}

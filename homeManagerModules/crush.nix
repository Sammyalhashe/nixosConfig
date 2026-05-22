{
  config,
  lib,
  pkgs,
  osConfig ? { },
  ...
}:

let
  hostname = osConfig.networking.hostName or "unknown";
  inferenceHost = if hostname == "mothership" then "127.0.0.1" else "11.125.37.101";

  # New structure based on crush.json schema
  crushConfig = {
    options = {
      disable_default_providers = true;
    };
    providers = {
      local-inference = {
        type = "openai";
        base_url = "http://${inferenceHost}:4000/v1";
        name = "Mothership (LiteLLM)";
        api_key = "none";
        models = [
          {
            name = "Qwen3.6";
            id = "qwen3.6";
            cost_per_1m_in = 0.0;
            cost_per_1m_out = 0.0;
            cost_per_1m_in_cached = 0.0;
            cost_per_1m_out_cached = 0.0;
            context_window = 128000;
            default_max_tokens = 8192;
            can_reason = false;
            supports_attachments = false;
          }
        ];
      };
      openrouter = {
        type = "openai";
        base_url = "https://openrouter.ai/api/v1";
        name = "OpenRouter";
        api_key = "env:OPENROUTER_API_KEY";
        models = [
          {
            name = "MiMo-V2-Omni (Free)";
            id = "xiaomi/mimo-v2-omni:free";
          }
        ];
      };
    };
  };
in
{
  # Only write this config if crush is actually installed in the profile
  config = lib.mkIf (builtins.elem pkgs.nur.repos.charmbracelet.crush config.home.packages) {
    # Write to both locations to be safe
    xdg.configFile."crush/crush.json".text = builtins.toJSON crushConfig;
    xdg.configFile."crush/config.yaml".text = lib.generators.toYAML { } crushConfig;
  };
}

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
  litellmUrl = "http://${inferenceHost}:4000";
in
{
  home.packages = [ pkgs.claude-code ];

  # ~/.claude/settings.json — user-scope settings applied on every startup.
  # The env block is the only reliable way to set several of these vars;
  # shell exports are ignored for some of them (e.g. attribution header).
  home.file.".claude/settings.json".text = builtins.toJSON {
    "$schema" = "https://json.schemastore.org/claude-code-settings.json";
    env = {
      ANTHROPIC_BASE_URL = litellmUrl;
      # LiteLLM doesn't require a real key; any non-empty string works.
      ANTHROPIC_AUTH_TOKEN = "sk-no-key-required";
      # Strip anthropic-beta headers that LiteLLM may reject.
      CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS = "1";
      CLAUDE_CODE_ENABLE_TELEMETRY = "0";
      CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
    };
    # Must match a model_name exposed by LiteLLM.
    model = "gemma-4";
    # Suppress co-authored-by attribution in commits/PRs.
    attribution = {
      commit = "";
      pr = "";
    };
  };

  # ~/.claude.json — skip the interactive onboarding/login flow on first run.
  home.file.".claude.json".text = builtins.toJSON {
    hasCompletedOnboarding = true;
    primaryApiKey = "sk-no-key-required";
  };
}

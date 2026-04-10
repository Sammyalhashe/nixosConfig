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

  claudeSettings = {
    "$schema" = "https://json.schemastore.org/claude-code-settings.json";
    env = {
      ANTHROPIC_BASE_URL = litellmUrl;
      # LiteLLM doesn't require a real key; any non-empty string works.
      ANTHROPIC_AUTH_TOKEN = "sk-no-key-required";
      ANTHROPIC_API_KEY = "sk-no-key-required";
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

  claudeOnboarding = {
    hasCompletedOnboarding = true;
    primaryApiKey = "sk-no-key-required";
  };
in
{
  home.packages = [ pkgs.claude-code ];

  # Use activation script to create writable configuration files.
  # Claude Code tries to write to its configuration files on every startup 
  # (e.g., to update lock files or session state), which fails if they 
  # are symlinked to the read-only Nix store.
  home.activation.setupClaudeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p $HOME/.claude
    
    # Create ~/.claude/settings.json as a writable file
    $DRY_RUN_CMD cp -f ${pkgs.writeText "claude-settings.json" (builtins.toJSON claudeSettings)} $HOME/.claude/settings.json
    $DRY_RUN_CMD chmod +w $HOME/.claude/settings.json
    
    # Create ~/.claude.json as a writable file
    $DRY_RUN_CMD cp -f ${pkgs.writeText "claude-onboarding.json" (builtins.toJSON claudeOnboarding)} $HOME/.claude.json
    $DRY_RUN_CMD chmod +w $HOME/.claude.json
  '';

  # Set environment variables directly to ensure they are available to the shell.
  home.sessionVariables = {
    ANTHROPIC_BASE_URL = litellmUrl;
    ANTHROPIC_API_KEY = "sk-no-key-required";
    CLAUDE_CODE_DISABLE_TELEMETRY = "0";
  };
}

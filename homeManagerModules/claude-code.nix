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
      # Fix for 90% slowdown in local models: Disable attribution header to preserve KV cache
      CLAUDE_CODE_ATTRIBUTION_HEADER = "0";
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

  # Andrej Karpathy Coding Skills/Principles for Claude Code (Applied via CLAUDE.md)
  karpathySkills = ''
    # Andrej Karpathy's Coding Principles
    
    ## 1. Think Before Coding
    - State assumptions clearly.
    - Present multiple interpretations of the task.
    - If a task is ambiguous, STOP and ask for clarification instead of guessing.
    
    ## 2. Simplicity First
    - Write the minimum amount of code required to solve the problem.
    - Avoid speculative features, premature abstractions, or "just-in-case" logic.
    - Favor standard libraries and established patterns over clever tricks.
    
    ## 3. Surgical Changes
    - Touch ONLY the lines necessary for the requested change.
    - Match the existing style, indentation, and naming conventions of the file perfectly.
    - Do not perform unrelated refactors or "cleanups" unless explicitly asked.
    
    ## 4. Goal-Driven Execution
    - Transform every task into a verifiable goal.
    - If fixing a bug, first write a test that reproduces it, then implement the fix.
    - Verification is mandatory. A task is not done until it is proven correct.
  '';
in
{
  home.packages = [ pkgs.claude-code ];

  # Global Karpathy Principles for all projects
  home.file."CLAUDE.md".text = karpathySkills;

  # Use activation script to create writable configuration files.
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

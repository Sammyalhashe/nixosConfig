{
  config,
  lib,
  pkgs,
  osConfig ? { },
  ...
}:
let
  cfg = config.services.claude-code;
  hostname = osConfig.networking.hostName or "unknown";
  inferenceHost = if hostname == "mothership" then "127.0.0.1" else "11.125.37.101";
  litellmUrl = "http://${inferenceHost}:4000";

  claudeSettings = {
    "$schema" = "https://json.schemastore.org/claude-code-settings.json";
    env = {
      ANTHROPIC_BASE_URL = litellmUrl;
      ANTHROPIC_AUTH_TOKEN = "sk-no-key-required";
      ANTHROPIC_API_KEY = "sk-no-key-required";
      CLAUDE_CODE_ATTRIBUTION_HEADER = "0";
      CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS = "1";
      CLAUDE_CODE_ENABLE_TELEMETRY = "0";
      CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
    };
    model = "qwen3.6";
    attribution = {
      commit = "";
      pr = "";
    };
  };

  locallyDefinedMcps = {
    HA = {
      type = "http";
      url = "https://homeassistant.salh.xyz/api/mcp";
      oauth = {
        # Note: Do not change this clientId to your Home Assistant URL.
        # It must point to the local loopback address Claude Code binds during OAuth.
        clientId = "http://localhost:12345";
        client_id = "http://localhost:12345"; # Fallback for CLI version variations

        callbackPort = 12345;
        callback_port = 12345; # Fallback for CLI version variations
      };
    };
    robinhood-trading = {
      url = "https://agent.robinhood.com/mcp/trading";
      auth = "oauth"; # Automatically coordinates PKCE dynamic registration & background token refreshes
    };
  };

  claudeJson = {
    hasCompletedOnboarding = true;
    primaryApiKey = "sk-no-key-required";
  }
  // lib.optionalAttrs (locallyDefinedMcps != { }) {
    mcpServers = locallyDefinedMcps;
  }
  // lib.optionalAttrs (cfg.mcpServers != { }) {
    mcpServers = cfg.mcpServers;
  };

  mergeClaudeJsonScript =
    pkgs.writeText "merge-claude-json.py"
      # python
      ''
        import json, os, sys

        path = os.path.expanduser("~/.claude.json")
        desired = json.loads(sys.argv[1])

        existing = {}
        if os.path.exists(path):
            with open(path) as f:
                existing = json.load(f)

        existing.update(desired)

        with open(path, "w") as f:
            json.dump(existing, f, indent=2)
      '';

  karpathySkills =
    # markdown
    ''
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
  options.services.claude-code.mcpServers = lib.mkOption {
    type = lib.types.attrs;
    default = { };
    description = "MCP servers to configure in Claude Code settings.";
  };

  config = {
    home.packages = [ pkgs.claude-code ];

    home.file."CLAUDE.md".text = karpathySkills;

    home.activation.setupClaudeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p $HOME/.claude

      $DRY_RUN_CMD cp -f ${pkgs.writeText "claude-settings.json" (builtins.toJSON claudeSettings)} $HOME/.claude/settings.json
      $DRY_RUN_CMD chmod +w $HOME/.claude/settings.json

      $DRY_RUN_CMD ${pkgs.python3}/bin/python3 ${mergeClaudeJsonScript} ${lib.escapeShellArg (builtins.toJSON claudeJson)}
    '';

    home.sessionVariables = {
      ANTHROPIC_BASE_URL = litellmUrl;
      ANTHROPIC_API_KEY = "sk-no-key-required";
      CLAUDE_CODE_DISABLE_TELEMETRY = "0";
    };
  };
}

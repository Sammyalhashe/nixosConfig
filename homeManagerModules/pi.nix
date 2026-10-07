{
  lib,
  pkgs,
  osConfig ? { },
  ...
}:
let
  hostname = osConfig.networking.hostName or "unknown";
  inferenceHost = if hostname == "mothership" then "127.0.0.1" else "11.125.37.101";
  litellmUrl = "http://${inferenceHost}:4000";

  # Mothership's LiteLLM routes, exposed to pi as one custom provider. pi speaks
  # OpenAI chat completions to LiteLLM, which forwards to llama-server.
  piModels = {
    providers.mothership = {
      baseUrl = "${litellmUrl}/v1";
      api = "openai-completions";
      # LiteLLM runs without auth, but pi hides keyless providers from /model.
      apiKey = "sk-no-key-required";
      # Qwen's chat template raises on the `developer` role pi uses for
      # reasoning models, and llama-server has no reasoning_effort.
      compat = {
        supportsDeveloperRole = false;
        supportsReasoningEffort = false;
      };
      models = [
        {
          id = "qwen3.8";
          name = "Qwen3.8 (mothership)";
          reasoning = true;
          contextWindow = 65536;
        }
        {
          id = "qwen3.8-fast";
          name = "Qwen3.8, no thinking (mothership)";
          reasoning = false;
          contextWindow = 65536;
        }
        {
          id = "qwen-flash";
          name = "Qwen Flash 7B (mothership)";
          reasoning = false;
          contextWindow = 32768;
        }
      ];
    };
  };

  piSettings = {
    defaultProvider = "mothership";
    defaultModel = "qwen3.8";
  };

  # pi rewrites settings.json at runtime (/settings, /model), so merge our keys
  # into it rather than owning the file.
  mergeSettingsScript =
    pkgs.writeText "merge-pi-settings.py"
      # python
      ''
        import json, os, sys

        path = os.path.expanduser("~/.pi/agent/settings.json")
        desired = json.loads(sys.argv[1])

        existing = {}
        if os.path.exists(path):
            with open(path) as f:
                existing = json.load(f)

        existing.update(desired)

        with open(path, "w") as f:
            json.dump(existing, f, indent=2)
      '';
in
{
  home.packages = [ pkgs.llm-agents.pi ];

  # pi only reads models.json, so home-manager can own it.
  home.file.".pi/agent/models.json".text = builtins.toJSON piModels;

  home.activation.setupPiSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p $HOME/.pi/agent
    $DRY_RUN_CMD ${pkgs.python3}/bin/python3 ${mergeSettingsScript} ${lib.escapeShellArg (builtins.toJSON piSettings)}
  '';
}

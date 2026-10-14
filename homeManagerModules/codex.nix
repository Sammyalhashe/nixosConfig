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

  modelsJsonPath = "${config.home.homeDirectory}/.codex/models.json";

  # Codex's fallback values, except the window and modalities, which match
  # modules/ai/llm-services/models/qwen3-8-flash-next.nix. Replaces the built-in catalog.
  qwenModelInfo = {
    slug = "qwen3.8";
    display_name = "Qwen3.8-Flash-Next";
    description = "Local Qwen3.8-Flash-Next served via Mothership LiteLLM.";
    supported_reasoning_levels = [ ];
    shell_type = "unified_exec";
    visibility = "list";
    supported_in_api = true;
    priority = 0;
    availability_nux = null;
    upgrade = null;
    support_verbosity = false;
    default_verbosity = null;
    apply_patch_tool_type = null;
    truncation_policy = {
      mode = "bytes";
      limit = 10000;
    };
    context_window = 65536;
    max_context_window = 65536;
    experimental_supported_tools = [ ];
    input_modalities = [ "text" ];
    # Codex rejects a catalog entry without instructions; this is its own fallback
    # prompt (codex-rs/models-manager/prompt.md, Apache-2.0).
    base_instructions = builtins.readFile ./codex-base-instructions.md;
  };

  modelsCatalog = pkgs.writeText "codex-models.json" (
    builtins.toJSON { models = [ qwenModelInfo ]; }
  );

  # Codex 0.159.3 removed `wire_api = "chat"`; LiteLLM also serves /v1/responses.
  codexSettings = {
    model = "qwen3.8";
    model_provider = "mothership";
    model_providers.mothership = {
      name = "Mothership (LiteLLM)";
      base_url = "${litellmUrl}/v1";
      wire_api = "responses";
    };

    check_for_update_on_startup = false;
    analytics.enabled = false;
    feedback.enabled = false;

    model_catalog_json = modelsJsonPath;

    projects = {
      "${config.home.homeDirectory}".trust_level = "trusted";
      "${config.home.homeDirectory}/nixosConfig".trust_level = "trusted";
    };

    # OAuth login for each server is a separate, manual step: `codex mcp login <name>`.
    mcp_servers = {
      # Home Assistant has no OAuth dynamic client registration, so use a
      # long-lived access token exported as HA_MCP_TOKEN.
      HA = {
        url = "https://homeassistant.salh.xyz/api/mcp";
        bearer_token_env_var = "HA_MCP_TOKEN";
      };
      robinhood-trading.url = "https://agent.robinhood.com/mcp/trading";
      coinbase.url = "https://agents.coinbase.com/mcp";
    };
  };

  codexConfig = (pkgs.formats.toml { }).generate "codex-config.toml" codexSettings;
in
{
  config = {
    home.packages = [ pkgs.codex ];

    home.file.".codex/AGENTS.md".source = ./ai-instructions.md;
    home.file.".codex/models.json".source = modelsCatalog;

    # programs.codex would symlink config.toml into the read-only Nix store;
    # Codex rewrites this file at runtime, so copy it in mutably instead.
    home.activation.setupCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p $HOME/.codex

      $DRY_RUN_CMD cp -f ${codexConfig} $HOME/.codex/config.toml
      $DRY_RUN_CMD chmod 600 $HOME/.codex/config.toml
    '';
  };
}

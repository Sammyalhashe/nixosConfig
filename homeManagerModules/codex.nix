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

    projects = {
      "${config.home.homeDirectory}".trust_level = "trusted";
      "${config.home.homeDirectory}/nixosConfig".trust_level = "trusted";
    };

    # OAuth login for each server is a separate, manual step: `codex mcp login <name>`.
    mcp_servers = {
      HA.url = "https://homeassistant.salh.xyz/api/mcp";
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

    # programs.codex would symlink config.toml into the read-only Nix store;
    # Codex rewrites this file at runtime, so copy it in mutably instead.
    home.activation.setupCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p $HOME/.codex

      $DRY_RUN_CMD cp -f ${codexConfig} $HOME/.codex/config.toml
      $DRY_RUN_CMD chmod 600 $HOME/.codex/config.toml
    '';
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.coinbase-cli;
  keyFilePath = "/home/${config.home.username}/hardware_maker_api_key.json";

  # coinbase-cli 0.0.11 ignores `mcp --key-file`; it reads COINBASE_KEY_* and
  # needs a named environment. The config dir is temporary so nothing persists.
  mcp = pkgs.writeShellApplication {
    name = "coinbase-mcp";
    runtimeInputs = [
      pkgs.nodejs_22
      pkgs.jq
      pkgs.coreutils
    ];
    text = ''
      COINBASE_KEY_ID=$(jq -r .name ${keyFilePath})
      COINBASE_KEY_SECRET=$(jq -r .privateKey ${keyFilePath})
      COINBASE_CONFIG_DIR=$(mktemp -d)
      trap 'rm -rf "$COINBASE_CONFIG_DIR"' EXIT
      export COINBASE_KEY_ID COINBASE_KEY_SECRET COINBASE_CONFIG_DIR
      export COINBASE_ENV=live COINBASE_NO_UPDATE_CHECK=1 COINBASE_NO_HISTORY=1
      npx --yes @coinbase/coinbase-cli@0.0.11 mcp
    '';
  };
in
{
  options.programs.coinbase-cli = {
    enable = lib.mkEnableOption "Coinbase CDP CLI with MCP server for Claude Code";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.nodejs_22 ];

    programs.claude-code.mcpServers.coinbase = {
      command = lib.getExe mcp;
    };
  };
}

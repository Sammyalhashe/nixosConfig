{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.coinbase-cli;
  keyFilePath = "/home/${config.home.username}/hardware_maker_api_key.json";
in
{
  options.programs.coinbase-cli = {
    enable = lib.mkEnableOption "Coinbase CDP CLI with MCP server for Claude Code";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.nodejs_22 ];

    services.claude-code.mcpServers.coinbase = {
      command = "${pkgs.nodejs_22}/bin/npx";
      args = [
        "-y"
        "@coinbase/coinbase-cli"
        "mcp"
      ];
    };

    home.activation.setupCoinbaseCli = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -f "${keyFilePath}" ] && command -v coinbase &>/dev/null; then
        $DRY_RUN_CMD coinbase env live --key-file "${keyFilePath}" 2>/dev/null || true
      fi
    '';
  };
}

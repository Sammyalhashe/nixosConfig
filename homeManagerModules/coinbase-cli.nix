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

    programs.claude-code.mcpServers.coinbase = {
      command = "${pkgs.nodejs_22}/bin/npx";
      args = [
        "-y"
        "@coinbase/coinbase-cli"
        "mcp"
        "--key-file"
        "${keyFilePath}"
      ];
    };
  };
}

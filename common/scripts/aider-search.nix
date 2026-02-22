{ pkgs }:

pkgs.writeShellScriptBin "aider-search" ''
  # Extract API key securely
  export BRAVE_API_KEY=$(sops -d secrets.yaml | yq -r .brave_api_key)

  if [ -z "$BRAVE_API_KEY" ]; then
    echo "Error: Could not retrieve Brave API key from secrets.yaml"
    exit 1
  fi

  # Launch Aider with the MCP server
  echo "Starting Aider with Brave Search MCP..."
  exec ${pkgs.aider-chat}/bin/aider \
    --model openai/qwen3-coder \
    --openai-api-base http://127.0.0.1:8012/v1 \
    --no-auto-commits \
    --mcp-server "npx -y @modelcontextprotocol/server-brave-search"
''

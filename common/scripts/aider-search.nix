{ pkgs }:

pkgs.writeShellScriptBin "aider-search" ''
  # Extract API key securely
  export BRAVE_API_KEY=$(sops -d secrets.yaml | yq -r .brave_api_key)

  if [ -z "$BRAVE_API_KEY" ]; then
    echo "Error: Could not retrieve Brave API key from secrets.yaml"
    exit 1
  fi

  # Create a unique temporary config file in /tmp
  TEMP_CONFIG=$(mktemp /tmp/aider-config-XXXXXX.yml)
  cat <<EOF > "$TEMP_CONFIG"
mcp-servers:
  - "npx -y @modelcontextprotocol/server-brave-search"
EOF

  # Launch Aider with the absolute path to the temporary config
  echo "Starting Aider with Brave Search MCP..."
  trap 'rm -f "$TEMP_CONFIG"' EXIT
  exec ${pkgs.aider-chat-with-browser}/bin/aider \
    --model openai/qwen3-coder \
    --openai-api-base http://127.0.0.1:8012/v1 \
    --no-auto-commits \
    --config "$TEMP_CONFIG" "$@"
''

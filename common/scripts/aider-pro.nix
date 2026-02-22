{ pkgs }:

pkgs.writeShellScriptBin "aider-pro" ''
  # Aider wrapper for Dual-Model "Architect-Editor" workflow via LiteLLM Proxy
  # Port 8000: LiteLLM Proxy (Routing to 8013 and 8012)

  exec ${pkgs.aider-chat}/bin/aider \
    --architect \
    --model openai/gpt-oss \
    --editor-model openai/qwen-coder \
    --openai-api-base http://127.0.0.1:8000/v1 \
    --openai-api-key none \
    --auto-accept-architect \
    --stream \
    "$@"
''

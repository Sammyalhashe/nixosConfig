{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./backend
    ./gpt-oss.nix
    ./qwen-coder.nix
    ./qwen-flash.nix
    ./litellm.nix
    ./litellm-uv.nix
    ./gemma.nix
    ./hermes-3-llama-3.1-70B.nix
  ];
}

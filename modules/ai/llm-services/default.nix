{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./gpt-oss.nix
    ./qwen-coder.nix
    ./qwen-flash.nix
    ./litellm.nix
    ./litellm-uv.nix
    ./gemma.nix
  ];
}

{ config, lib, pkgs, ... }:

{
  imports = [
    ./gpt-oss.nix
    ./qwen-coder.nix
  ];
}

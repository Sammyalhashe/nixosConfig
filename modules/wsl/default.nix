{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.environments.wsl.enable = lib.mkEnableOption "Whether to enable WSL specific settings";
}

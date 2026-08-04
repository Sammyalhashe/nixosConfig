{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.environments.wsl.enable = lib.mkEnableOption "Whether to enable WSL specific settings";

  config = lib.mkIf config.environments.wsl.enable {
    # WSL manages /etc/resolv.conf itself (via nixos-wsl), so the NixOS
    # resolvconf service must be disabled to avoid a conflicting
    # environment.etc."resolv.conf" definition.
    networking.resolvconf.enable = lib.mkForce false;
  };
}

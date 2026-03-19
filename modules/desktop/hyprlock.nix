{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  config = lib.mkIf config.host.enableHyprland {
    security.pam.services.hyprlock = { };
    programs.hyprlock = {
      enable = true;
      package = inputs.hyprlock.packages.${pkgs.stdenv.hostPlatform.system}.hyprlock;
    };
  };
}

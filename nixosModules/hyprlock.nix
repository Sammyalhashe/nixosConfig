{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  security.pam.services.hyprlock = { };
  programs.hyprlock = {
    enable = true;
    package = inputs.hyprlock.packages.${pkgs.stdenv.hostPlatform.system}.hyprlock;
  };
}

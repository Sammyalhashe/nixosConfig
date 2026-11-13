{
  config,
  pkgs,
  lib,
  ...
}:
let
  fishIsDefault = config.home-manager.users.${config.host.username}.shells.fish.enable or false;
in
{
  programs.fish.enable = lib.mkIf fishIsDefault true;
  users.defaultUserShell = if fishIsDefault then pkgs.fish else pkgs.nushell;
}

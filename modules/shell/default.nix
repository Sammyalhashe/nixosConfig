{
  config,
  pkgs,
  lib,
  ...
}:

{
  users.defaultUserShell = pkgs.nushell;
}

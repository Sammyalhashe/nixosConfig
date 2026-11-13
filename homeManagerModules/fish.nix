{ config, lib, ... }:
let
  nushellOnly = [
    "fg"
    "pop"
    "pops"
  ];
  aliases = removeAttrs config.programs.nushell.shellAliases nushellOnly // {
    pop = "env RESEND_API_KEY=(skate get pop-resend-key@api-keys | string trim) pop";
    pops = "env RESEND_API_KEY=(skate get pop-resend-key@api-keys | string trim) pop --from sammy@salh.xyz";
  };
in
{
  # conf.d rather than programs.fish: Ryoku owns config.fish (see lig.nix).
  xdg.configFile."fish/conf.d/aliases.fish".text = lib.concatLines (
    lib.mapAttrsToList (name: cmd: "alias ${name} ${lib.escapeShellArg cmd}") aliases
  );
}

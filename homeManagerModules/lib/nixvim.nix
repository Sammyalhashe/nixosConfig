# The nixvim package from this flake's nixvim input, themed by stylix when the
# importing home config enables it. `overrides` is a nixvim module applied
# first (e.g. { nixvim.wsl = true; }).
#
#   import ../../homeManagerModules/lib/nixvim.nix { inherit pkgs inputs config; } { }
{
  pkgs,
  inputs,
  config,
}:
overrides:
let
  base = inputs.nixvim.packages.${pkgs.stdenv.hostPlatform.system}.default;
  package = if overrides == { } then base else base.extend overrides;
in
if (config.stylix.enable or false) && (config.stylix.targets.nixvim.enable or false) then
  package.extend config.stylix.targets.nixvim.exportedModule
else
  package

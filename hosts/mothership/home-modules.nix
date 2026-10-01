{ lib, inputs, ... }:
let
  my_imports = [
    ../../homeManagerModules/home-common.nix
    ../../homeManagerModules/neovim.nix
    ../../homeManagerModules/stylix.nix
    ../../homeManagerModules/aider.nix
    ../../homeManagerModules/opencode.nix
  ];
in
{
  imports = my_imports;
}

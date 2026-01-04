{ lib, inputs, ... }:
let
  my_imports = [
    ./home-common.nix
    ./neovim.nix
    ./wofi.nix
    ./stylix.nix
  ];
in
{
  imports = my_imports;
}

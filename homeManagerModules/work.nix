{ lib, inputs, ... }:
let
  my_imports = [
    ./home-common.nix
    ./neovim.nix
    ./aider.nix
  ];
in
{
  imports = my_imports;
}

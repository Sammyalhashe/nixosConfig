{ lib, inputs, ... }:
let
  my_imports = [
    ./home-common.nix
    ./neovim.nix
    ./aider.nix
    ./ghostty.nix
    ./aerospace.nix
  ];
in
{
  imports = my_imports;
}

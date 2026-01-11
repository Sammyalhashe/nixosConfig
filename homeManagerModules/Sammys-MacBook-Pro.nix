{ lib, inputs, ... }:
let
  my_imports = [
    ./home-common.nix
  ];
in
{
  imports = my_imports;
}

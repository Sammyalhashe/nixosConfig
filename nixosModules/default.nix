{ config, pkgs, lib, ... }:

{
  imports = [
    ./options.nix
    ./desktop.nix
    ./shell.nix
    ./kdestuff.nix
    ./greetd.nix
  ];
}

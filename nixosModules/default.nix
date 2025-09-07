{
  username,
  greetd ? false,
  wsl ? false,
}:
{
  lib,
  inputs,
  pkgs,
  ...
}@args:
{
  imports =
    if wsl then
      [
        ./shell.nix
        ./kdestuff.nix
      ]
    else if greetd then
      [
        (import ./greetd.nix {
          inherit
            pkgs
            username
            inputs
            lib
            ;
        })
      ]
    else
      [
        ./desktop.nix
        ./shell.nix
        ./kdestuff.nix
      ];
}

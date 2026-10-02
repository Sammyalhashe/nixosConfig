{ lib, inputs, ... }:
let
  my_imports = [
    ../../homeManagerModules/home-common.nix
    ../../homeManagerModules/neovim.nix
    ../../homeManagerModules/stylix.nix
    {
      programs.coinbase-cli.enable = true;
      environments.wsl.enable = true;
      environments.wsl.windowsUsername = "sammy";
    }
  ];
in
{
  imports = my_imports;
}

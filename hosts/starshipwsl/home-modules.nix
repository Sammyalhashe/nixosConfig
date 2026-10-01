{ lib, inputs, ... }:
let
  my_imports = [
    ../../homeManagerModules/home-common.nix
    ../../homeManagerModules/neovim.nix
    ../../homeManagerModules/stylix.nix
    ../../homeManagerModules/aider.nix
    {
      environments.wsl.enable = true;
      environments.wsl.windowsUsername = "sammy";
    }
  ];
in
{
  imports = my_imports;
}

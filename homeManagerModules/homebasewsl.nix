{ lib, inputs, ... }:
let
  my_imports = [
    ./home-common.nix
    ./neovim.nix
    ./wofi.nix
    ./stylix.nix
    ./aider.nix
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

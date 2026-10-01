{
  config,
  pkgs,
  inputs,
  user,
  homeDir,
  ...
}:
{
  imports = [
    ../../homeManagerModules/wsl-base.nix
    ./home-modules.nix
  ];

  home.username = "${user}";

  home.packages = with pkgs; [
    lazygit
  ];
}

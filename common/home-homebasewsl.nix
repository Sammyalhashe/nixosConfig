{
  config,
  pkgs,
  inputs,
  user,
  homeDir,
  ...
}:
{
  imports = [ ./home-wsl-common.nix ];

  home.username = "${user}";

  home.packages = with pkgs; [
    lazygit
    thunar
  ];
}

{
  pkgs,
  user,
  ...
}:
{
  imports = [
    ./home-default.nix
  ];

  programs.aider.enable = true;

  home.username = "${user}";

  home.stateVersion = "24.05"; # Please read the comment before changing.

  home.packages = with pkgs; [
    onlyoffice-desktopeditors
    cloudflare-warp
  ];
}

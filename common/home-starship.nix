{
  pkgs,
  user,
  ...
}:
{
  imports = [
    ./home-default.nix
  ];

  # See this module for an example on how
  # to create a good home-manager option
  # I don't use it because it turns out
  # that vicinae comes with it's own flake.
  # host.vicinae.enable = true;

  programs.aider.enable = true;
  programs.coinbase-cli.enable = true;

  home.username = "${user}";

  home.stateVersion = "24.05"; # Please read the comment before changing.

  home.packages = with pkgs; [
    onlyoffice-desktopeditors
    cloudflare-warp
  ];
}

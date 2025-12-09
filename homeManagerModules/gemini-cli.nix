{
  config,
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.gemini-cli ];
}
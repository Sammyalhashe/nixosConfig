{
  inputs,
  ...
}:
{
  imports = [
    ./zellij.nix
    ./nushell.nix
    ./wsl.nix
    inputs.nix-moltbot.homeManagerModules.moltbot
  ];

  # programs.moltbot.enable = true;
  programs.starship.enable = true;
  programs.git = {
    enable = true;
    userName = "Sammy Al Hashemi";
    userEmail = "sammy@salh.xyz";
  };
  home.stateVersion = "23.11";
}

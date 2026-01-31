{
  inputs,
  ...
}:
{
  imports = [
    ./zellij.nix
    ./nushell.nix
    ./wsl.nix
  ];

  programs.starship.enable = true;
  programs.git = {
    enable = true;
    settings = {
      user.name = "Sammy Al Hashemi";
      user.email = "sammy@salh.xyz";
    };
  };
  home.stateVersion = "23.11";
}

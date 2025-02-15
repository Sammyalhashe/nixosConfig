# https://fnordig.de/til/nix/home-manager-allow-unfree.html
{ pkgs, ... }: {
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };
}

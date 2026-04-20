{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./options.nix
    ./desktop
    ./shell
    ./networking
    ./security/sops.nix
    ./security/cachix.nix
    ./security/trusted-keys.nix
    ./monitoring
    ./hardware/breezy-desktop.nix
  ];
}

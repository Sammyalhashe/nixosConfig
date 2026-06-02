{
  ...
}:

{
  imports = [
    ./crypto
    ./desktop
    ./hardware/breezy-desktop.nix
    ./monitoring
    ./networking
    ./options.nix
    ./security/cachix.nix
    ./security/sops.nix
    ./security/trusted-keys.nix
    ./shell
  ];
}

{
  ...
}:

{
  imports = [
    ./constants.nix
    ./crypto
    ./desktop
    ./hardware-wallets.nix
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

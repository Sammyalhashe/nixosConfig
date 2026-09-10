{
  ...
}:

{
  imports = [
    ./base
    ./constants.nix
    ./crypto
    ./desktop
    ./hardware-wallets.nix
    ./hardware/bluetooth.nix
    ./hardware/breezy-desktop.nix
    ./hardware/nvidia.nix
    ./monitoring
    ./networking
    ./options.nix
    ./security/cachix.nix
    ./security/sops.nix
    ./security/trusted-keys.nix
    ./services
    ./shell
  ];
}

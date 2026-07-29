{
  pkgs,
  ...
}:
{
  imports = [
    ./coinbase-sweep.nix
  ];
  

  hardware.ledger.enable = true;
  environment.systemPackages = [
    pkgs.ledger-live-desktop
  ];
 

  services.trezord.enable = true;
}

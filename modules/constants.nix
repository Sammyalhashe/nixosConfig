{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.hostKeys = mkOption {
    type = types.attrsOf types.str;
    default = {
      homebase = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO2hNthWiWeNoxH848/Vhdkc8jWNJw7690ZNAh8RVE9d sammy@salh.xyz";
    };
    description = "Per-host SSH public keys.";
  };
}

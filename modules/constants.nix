{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.hostKeys = mkOption {
    type = types.attrsOf types.str;
    default = {
      homebase = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO2hNthWiWeNoxH848/Vhdkc8jWNJw7690ZNAh8RVE9d sammy@salh.xyz";
      mothership = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPx5JBI3FNtugjdVeb1Gg4lUEJvGa/eiZ6rnsIN/oC3f sammy@salh.xyz";
      # TODO: replace with starship's real ed25519 public key.
      starship = "ssh-ed25519 AAAA_REPLACE_ME_STARSHIP_PUBLIC_KEY sammy@salh.xyz";
    };
    description = "Per-host SSH public keys.";
  };
}

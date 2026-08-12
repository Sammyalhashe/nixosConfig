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
      starship = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINUptk+nhbHYTfUJvGT3/X4vkKWRotT5ckw8BiQuADml sammy@salh.xyz";
      oldboy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGvEm47CyJZ/UzNn3uySsiOENhFjZapoaeOmpAxWSrPO sammy@salh.xyz";
    };
    description = "Per-host SSH public keys.";
  };
}

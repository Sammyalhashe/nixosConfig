{ config, lib, inputs, ... }:

let
  cfg = config.host;

  omarchyConfig = {
    full_name = "Sammy Al Hashemi";
    email_address = "sammy@salh.xyz";
    theme = lib.mkForce "generated_dark";
    theme_overrides = {
      wallpaper_path = lib.mkForce ./assets/BLACK_VII_desktop.jpg;
    };
  };
in
{
  # Configure omarchy in NixOS/Darwin system config
  omarchy = omarchyConfig;

  # Configure omarchy in Home Manager
  home-manager.users.${cfg.username} = {
    imports = [ inputs.omarchy-nix.homeManagerModules.default ];
    omarchy = omarchyConfig;
  };
}

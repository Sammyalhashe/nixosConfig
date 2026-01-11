{ config, lib, inputs, options, ... }:

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
  config = lib.mkMerge [
    # Configure omarchy in NixOS/Darwin system config if option exists and enabled
    (if (options ? omarchy) then {
      omarchy = lib.mkIf cfg.useOmarchy omarchyConfig;
    } else {})

    # Configure omarchy in Home Manager if enabled
    (lib.mkIf cfg.useOmarchy {
      home-manager.users.${cfg.username} = {
        imports = [ inputs.omarchy-nix.homeManagerModules.default ];
        omarchy = omarchyConfig;
      };
    })
  ];
}

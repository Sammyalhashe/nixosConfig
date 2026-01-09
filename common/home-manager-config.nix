{ config, lib, pkgs, inputs, options, ... }:

let
  cfg = config.host;
  # Conditionally import Stylix HM module if not already present in NixOS/Darwin options
  # to avoid "read-only option set multiple times" error.
  stylixModule = if (options ? stylix) then [] else [ inputs.stylix.homeManagerModules.stylix ];

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
  config = {
    # Configure omarchy in NixOS/Darwin system config if enabled
    omarchy = lib.mkIf cfg.useOmarchy omarchyConfig;

    # Standard home-manager setup
    home-manager = {
      extraSpecialArgs = {
        inherit inputs;
        user = cfg.username;
        homeDir = if pkgs.stdenv.isDarwin then "/Users/${cfg.username}" else "/home/${cfg.username}";
        hostname = cfg.homeManagerHostname;
      };

      users.${cfg.username} = lib.mkMerge [
        {
          imports = stylixModule;
        }
        (lib.mkIf cfg.useOmarchy {
          imports = [ inputs.omarchy-nix.homeManagerModules.default ];

          # Configure omarchy in Home Manager
          omarchy = omarchyConfig;
        })
        {
          imports = [
            (./. + "/home-${cfg.homeManagerHostname}.nix")
            inputs.self.outputs.homeManagerModules.${cfg.homeManagerHostname} or {}
          ];
        }
      ];

      backupFileExtension = "backup";
    };
  };
}

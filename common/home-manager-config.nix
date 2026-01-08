{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.host;
in
{
  config = {
    # If omarchy is enabled, we add the omarchy config to home-manager user config
    home-manager.users.${cfg.username} = lib.mkIf cfg.useOmarchy {
      imports = [ inputs.omarchy-nix.homeManagerModules.default ];

      # Configure omarchy
      omarchy = {
        full_name = "Sammy Al Hashemi";
        email_address = "sammy@salh.xyz";
        theme = "generated_dark";
        theme_overrides = {
          wallpaper_path = ./assets/BLACK_VII_desktop.jpg;
        };
      };
    };

    # Standard home-manager setup
    home-manager = {
      extraSpecialArgs = {
        inherit inputs;
        user = cfg.username;
        homeDir = if pkgs.stdenv.isDarwin then "/Users/${cfg.username}" else "/home/${cfg.username}";
        hostname = cfg.homeManagerHostname;
      };

      users.${cfg.username} = {
        imports = [
          (./. + "/home-${cfg.homeManagerHostname}.nix")
          inputs.self.outputs.homeManagerModules.${cfg.homeManagerHostname} or {}
        ];
      };
      backupFileExtension = "backup";
    };
  };
}

{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.host;
in
{
  config = {
    # Standard home-manager setup
    home-manager = {
      extraSpecialArgs = {
        inherit inputs;
        user = cfg.username;
        homeDir = if pkgs.stdenv.isDarwin then "/Users/${cfg.username}" else "/home/${cfg.username}";
        hostname = cfg.homeManagerHostname;
      };

      users.${cfg.username} = lib.mkMerge [
        (lib.mkIf cfg.useOmarchy {
          imports = [ inputs.omarchy-nix.homeManagerModules.default ];

          # Configure omarchy
          omarchy = {
            full_name = "Sammy Al Hashemi";
            email_address = "sammy@salh.xyz";
            theme = lib.mkForce "generated_dark";
            theme_overrides = {
              wallpaper_path = ./assets/BLACK_VII_desktop.jpg;
            };
          };
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

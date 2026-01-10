{ config, lib, pkgs, inputs, options, ... }:

let
  cfg = config.host;
  # Conditionally import Stylix HM module if not already present in NixOS/Darwin options
  # to avoid "read-only option set multiple times" error.
  stylixModule = if (options ? stylix) then [] else [ inputs.stylix.homeManagerModules.stylix ];
in
{
  imports = [
    # Conditionally import omarchy config only if enabled.
    # This prevents the "option omarchy does not exist" error on systems that don't import omarchy-nix.
    (lib.mkIf cfg.useOmarchy { imports = [ ./omarchy-config.nix ]; })
  ];

  config = {
    # Standard home-manager setup
    home-manager = {
      extraSpecialArgs = {
        inherit inputs;
        user = cfg.username;
        homeDir = if pkgs.stdenv.isDarwin then "/Users/${cfg.username}" else "/home/${cfg.username}";
        hostname = cfg.homeManagerHostname;
      };

      users.${cfg.username} = {
        imports = stylixModule ++ [
          (./. + "/home-${cfg.homeManagerHostname}.nix")
          inputs.self.outputs.homeManagerModules.${cfg.homeManagerHostname} or {}
        ];
      };

      backupFileExtension = "backup";
    };
  };
}

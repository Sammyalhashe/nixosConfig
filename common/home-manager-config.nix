{
  config,
  lib,
  pkgs,
  inputs,
  options,
  ...
}:

let
  cfg = config.host;
  # Conditionally import Stylix HM module if not already present in NixOS/Darwin options
  # to avoid "read-only option set multiple times" error.
  stylixModule = if (options ? stylix) then [ ] else [ inputs.stylix.homeModules.stylix ];
in
{
  imports = [
    # Import omarchy config (which handles conditional logic internally)
    ./omarchy-config.nix
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
          inputs.self.outputs.homeModules.${cfg.homeManagerHostname} or { }
        ];
      };

      backupFileExtension = "backup";
    };
  };
}

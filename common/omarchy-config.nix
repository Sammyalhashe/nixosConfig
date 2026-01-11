{
  config,
  lib,
  inputs,
  options,
  ...
}:

let
  cfg = config.host;

  omarchyConfig = {
    full_name = "Sammy Al Hashemi";
    email_address = "sammy@salh.xyz";
    theme = lib.mkForce "generated_dark";
    theme_overrides = {
      # Use mkOverride 40 (between mkForce/mkDefault) to allow this to be the value used by Stylix
      # while avoiding conflicts with other modules. Kept as a path object for Stylix compatibility.
      wallpaper_path = lib.mkOverride 40 ./assets/BLACK_VII_desktop.jpg;
    };
  };
in
{
  config = lib.mkMerge [
    # Configure omarchy in NixOS/Darwin system config if option exists and enabled
    (
      if (options ? omarchy) then
        {
          omarchy = lib.mkIf cfg.useOmarchy omarchyConfig;
        }
      else
        { }
    )

    # Configure omarchy in Home Manager if enabled
    (lib.mkIf cfg.useOmarchy {
      home-manager.users.${cfg.username} = {
        imports = [ inputs.omarchy-nix.homeManagerModules.default ];
        omarchy = omarchyConfig;

        # Explicitly set the Hyprlock background path with higher priority (30) to override the
        # conflicting definition from omarchy-nix/stylix.
        # Must be converted to a string using toString because the Hyprlock module expects a string,
        # and passing a path object triggers a 'generators.mkValueStringDefault' error.
        programs.hyprlock.settings.background.path = lib.mkOverride 30 (
          toString ./assets/BLACK_VII_desktop.jpg
        );
      };
    })
  ];
}

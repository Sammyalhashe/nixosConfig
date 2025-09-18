{
  omarchy ? false,
}:
{
  inputs,
  user,
  homeDir,
  hostname ? "default",
  ...
}:
{
  # Configure omarchy
  omarchy = {
    full_name = "Sammy Al Hashemi";
    email_address = "sammy@salh.xyz";
    # theme = "tokyo-night";
    theme = "generated_dark";
    theme_overrides = {
      wallpaper_path = ./assets/BLACK_I_desktop.jpg;
    };
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs user homeDir; };
    users = {
      "${user}" = {
        imports = [
          ./home-${hostname}.nix
          inputs.self.outputs.homeManagerModules.${hostname}
        ]
        ++ [ inputs.omarchy-nix.homeManagerModules.default ];
      };
    };
    backupFileExtension = "backup";
  };
}

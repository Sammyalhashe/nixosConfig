{inputs, user, homeDir, hostname ? "default", ...}:
{
    home-manager = {
        extraSpecialArgs = { inherit inputs user homeDir; };
        users = {
            "${user}" = {
                imports = [
                    ./home-${hostname}.nix
                    inputs.self.outputs.homeManagerModules.${hostname}
                ];
            };
        };
        backupFileExtension = "backup";
    };
}

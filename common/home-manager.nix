{inputs, user, homeDir, ...}:
{
    home-manager = {
        extraSpecialArgs = { inherit inputs user homeDir; };
        users = {
            "${user}" = {
                imports = [
                    ./home.nix
                    inputs.self.outputs.homeManagerModules.default
                ];
            };
        };
        backupFileExtension = "backup";
    };
}

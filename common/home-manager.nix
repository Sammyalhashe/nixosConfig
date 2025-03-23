{inputs, user, ...}:
{
    home-manager = {
        extraSpecialArgs = { inherit inputs user; };
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

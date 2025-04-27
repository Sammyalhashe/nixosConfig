{inputs, user, ...}:
{
    home-manager = {
        extraSpecialArgs = { inherit inputs; };
        users = {
            "${user}" = {
                imports = [
                    ../../common/home.nix
                    inputs.self.outputs.homeManagerModules.default
                ];
            };
        };
        backupFileExtension = "backup";
    };
}

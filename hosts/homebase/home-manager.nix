{inputs, ...}:
let user = "salhashemi2";
in
{
    home-manager = {
        extraSpecialArgs = { inherit inputs; };
        users = {
            "${user}" = {
                imports = [
                    ./home.nix
                    inputs.self.outputs.homeManagerModules.default
                ];
            };
        };
    };
}

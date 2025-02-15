{inputs, zb, ...}:
let user = "salhashemi2";
in
{
    home-manager = {
        extraSpecialArgs = { inherit inputs; inherit zb; };
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

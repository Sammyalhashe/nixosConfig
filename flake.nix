{
  description = "Sammy Al Hashemi's flake for nix systems";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
  };

  outputs = { self, nixpkgs, zen-browser, ... }@inputs :
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      zb = zen-browser.packages.${system};
    in
  {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; inherit zb; };
          modules = [
              ./hosts/homebase/configuration.nix
              ./nixosModules
          ];
      };
      homeManagerModules.default = ./homeManagerModules;
  };
}

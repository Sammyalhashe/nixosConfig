{
  description = "Sammy Al Hashemi's flake for nix systems";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
  };

  outputs = { self, nixpkgs, darwin, zen-browser, ... }@inputs:
  {
      nixosConfigurations.homebase = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
              ./hosts/homebase/configuration.nix
              ./nixosModules
          ];
      };
      darwinConfigurations.Sammys-MacBook-Pro = darwin.lib.darwinSystem {
          specialArgs = { inherit inputs; };
          system = "x86_64-darwin";
          modules = [
              ./hosts/Sammys-MacBook-Pro/configuration.nix
          ];
      };
      homeManagerModules.default = ./homeManagerModules;
  };
}

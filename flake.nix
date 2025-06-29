{
  description = "Sammy Al Hashemi's flake for nix systems";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser = {
        url = "github:Sammyalhashe/zen-browser-flake";
        # IMPORTANT: we're using "libgbm" and is only available in unstable so ensure
        # to have it up-to-date or simply don't specify the nixpkgs input  
        inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprlock = {
        url = "github:hyprwm/hyprlock";
        inputs = {
          # hyprgraphics.follows = "hyprland/hyprgraphics";
          # hyprlang.follows = "hyprland/hyprlang";
          # hyprutils.follows = "hyprland/hyprutils";
          # nixpkgs.follows = "hyprland/nixpkgs";
          # systems.follows = "hyprland/systems";
        };
    };
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
  };

  outputs = { self, nixpkgs, darwin, zen-browser, hyprlock, nixos-wsl, ... }@inputs:
  {
      nixosConfigurations.homebase = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
              ./hosts/homebase/configuration.nix
              (import ./nixosModules { username = "salhashemi2"; })
          ];
      };
      nixosConfigurations.starshipwsl = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          system = "x86_64-linux";
          modules = [
              nixos-wsl.nixosModules.default
              ./hosts/starshipwsl/configuration.nix
              (import ./nixosModules { username = "salhashemi2"; wsl = true; })
          ];
      };
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
              ./hosts/starship/configuration.nix
              (import ./nixosModules { username = "salhashemi2"; })
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
      homeManagerModules.Sammys-MacBook-Pro = ./homeManagerModules/Sammys-MacBook-Pro.nix;
      homeManagerModules.starshipwsl = ./homeManagerModules/starshipwsl.nix;

      formatter.x86_64-linux = nixpkgs.legacyPackages."x86_64-linux".nixfmt-rfc-style;
  };
}

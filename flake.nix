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
    omarchy-nix = {
      url = "github:Sammyalhashe/omarchy-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    nixvim.url = "github:Sammyalhashe/nixvim";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      darwin,
      zen-browser,
      hyprlock,
      omarchy-nix,
      nixos-wsl,
      stylix,
      ...
    }@inputs:
    {
      nixosConfigurations.homebase = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/homebase/configuration.nix
          (import ./nixosModules { username = "salhashemi2"; })
        ];
      };
      nixosConfigurations.homebase_omarchy = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          (import ./hosts/homebase/configuration.nix { omarchy = true; })
          (import ./nixosModules {
            username = "salhashemi2";
            wsl = true; # just to not import the desktop file.
          })
          omarchy-nix.nixosModules.default
          stylix.nixosModules.stylix
          (import ./nixosModules/stylix.nix)
          {
            programs.stylix.enable = true;
          }
        ];
      };
      nixosConfigurations.oldboy = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          (import ./hosts/oldboy/configuration.nix { omarchy = true; })
          (import ./nixosModules {
            username = "salhashemi2";
            wsl = true; # just to not import the desktop file.
          })
          omarchy-nix.nixosModules.default
        ];
      };
      nixosConfigurations.starshipwsl = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        system = "x86_64-linux";
        modules = [
          nixos-wsl.nixosModules.default
          (import ./hosts/starshipwsl/configuration.nix { omarchy = false; })
          (import ./nixosModules {
            username = "salhashemi2";
            wsl = true;
          })
          (import ./nixosModules/wsl.nix)
          {
            environments.wsl.enable = true;
          }
          stylix.nixosModules.stylix
          (import ./nixosModules/stylix.nix)
          {
            programs.stylix.enable = true;
          }
        ];
      };
      nixosConfigurations.homebasewsl = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        system = "x86_64-linux";
        modules = [
          nixos-wsl.nixosModules.default
          ./hosts/homebasewsl/configuration.nix
          (import ./nixosModules {
            username = "nixos";
            wsl = true;
          })
          stylix.nixosModules.stylix
          (import ./nixosModules/stylix.nix)
          {
            programs.stylix.enable = true;
          }
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
      homeManagerModules.homebasewsl = ./homeManagerModules/homebasewsl.nix;

      formatter.x86_64-linux = nixpkgs.legacyPackages."x86_64-linux".nixfmt-rfc-style;
    };
}

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
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprlock = {
      url = "github:hyprwm/hyprlock";
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
      inputs.home-manager.follows = "home-manager";
    };
    nur.url = "github:nix-community/NUR";
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
      nur,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      nur-crush-overlay = final: prev: {
        crush = inputs.nur.repos.charmbracelet.crush;
      };
      overlays = [
        nur-crush-overlay
      ];
      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };

      # Shared base configuration
      baseConfig = {
        nixpkgs = {
           inherit overlays;
           config.allowUnfree = true;
        };
      };
    in
    {
      nixosConfigurations.homebase = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          baseConfig
          ./hosts/homebase/configuration.nix
          ./nixosModules
        ];
      };

      nixosConfigurations.homebase_omarchy = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          baseConfig
          ./hosts/homebase/configuration.nix
          ./nixosModules
          omarchy-nix.nixosModules.default
          stylix.nixosModules.stylix
          ./nixosModules/stylix.nix
          {
             host.useOmarchy = true;
             host.isWsl = true; # As per original config comment "just to not import the desktop file"
             programs.stylix.enable = true;
          }
        ];
      };

      nixosConfigurations.oldboy = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          baseConfig
          ./hosts/oldboy/configuration.nix
          ./nixosModules
          omarchy-nix.nixosModules.default
          {
             host.useOmarchy = true;
             host.isWsl = true;
          }
        ];
      };

      nixosConfigurations.starshipwsl = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        inherit system;
        modules = [
          baseConfig
          nixos-wsl.nixosModules.default
          ./hosts/starshipwsl/configuration.nix
          ./nixosModules
          ./nixosModules/wsl.nix
          {
            environments.wsl.enable = true;
            host.useOmarchy = false; # Explicitly set
          }
          stylix.nixosModules.stylix
          ./nixosModules/stylix.nix
          {
            programs.stylix.enable = true;
          }
        ];
      };

      nixosConfigurations.homebasewsl = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        inherit system;
        modules = [
          baseConfig
          {
            nixpkgs.overlays = [
              (final: prev: {
                wrapGAppsHook = prev.wrapGAppsHook3;
              })
            ];
          }
          nixos-wsl.nixosModules.default
          ./hosts/homebasewsl/configuration.nix
          ./nixosModules
          ./nixosModules/wsl.nix
          {
            environments.wsl.enable = true;
          }
          stylix.nixosModules.stylix
          ./nixosModules/stylix.nix
          {
            programs.stylix.enable = true;
          }
        ];
      };

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          baseConfig
          ./hosts/starship/configuration.nix
          ./nixosModules
        ];
      };

      darwinConfigurations.Sammys-MacBook-Pro = darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        system = "x86_64-darwin";
        modules = [
          ./hosts/Sammys-MacBook-Pro/configuration.nix
          ./nixosModules/options.nix
        ];
      };

      # Home-manager-only config for work
      homeConfigurations.work = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs;
          user = "salhashemi2";
          homeDir = "/root";
        };
        modules = [
          stylix.homeModules.stylix
          (import ./nixosModules/stylix.nix)
          {
            programs.stylix.enable = true;
          }
          ./homeManagerModules/work.nix
          ./common/home-work.nix
        ];
      };
      homeManagerModules.default = ./homeManagerModules;
      homeManagerModules.Sammys-MacBook-Pro = ./homeManagerModules/Sammys-MacBook-Pro.nix;
      homeManagerModules.starshipwsl = ./homeManagerModules/starshipwsl.nix;
      homeManagerModules.homebasewsl = ./homeManagerModules/homebasewsl.nix;

      formatter.x86_64-linux = nixpkgs.legacyPackages."x86_64-linux".nixfmt-rfc-style;
    };
}

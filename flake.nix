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
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
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
      treefmt-nix,
      nur,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      overlays = [
        nur.overlays.default
      ];
      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };

      treefmtEval = treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
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
          stylix.nixosModules.stylix
          ./nixosModules/stylix.nix
          { programs.stylix.enable = true; }
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
          stylix.nixosModules.stylix
          ./nixosModules/stylix.nix
          {
            host.useOmarchy = true;
            host.isWsl = true;
            programs.stylix.enable = true;
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
          stylix.nixosModules.stylix
          ./nixosModules/stylix.nix
          { programs.stylix.enable = true; }
        ];
      };

      darwinConfigurations.Sammys-MacBook-Pro = darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        system = "x86_64-darwin";
        modules = [
          baseConfig
          ./hosts/Sammys-MacBook-Pro/configuration.nix
          ./nixosModules/options.nix
        ];
      };

      # Home-manager-only config for work
      homeConfigurations.work = home-manager.lib.homeManagerConfiguration {
        # inherit pkgs; # <--- Removing this to define nixpkgs explicitly
        pkgs = import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };
        extraSpecialArgs = {
          inherit inputs;
          user = "salhashemi2";
          homeDir = "/root";
        };
        modules = [
          baseConfig
          stylix.homeModules.stylix
          (
            { pkgs, ... }:
            let
              theme = import ./common/stylix-values.nix { inherit pkgs; };
            in
            {
              stylix.enable = true;
              stylix.base16Scheme = theme.base16Scheme;
              stylix.image = theme.image;
              stylix.polarity = theme.polarity;
              stylix.fonts = theme.fonts;
            }
          )
          ./homeManagerModules/work.nix
          ./common/home-work.nix
        ];
      };
      homeModules.default = ./homeManagerModules;
      homeModules.Sammys-MacBook-Pro = ./homeManagerModules/Sammys-MacBook-Pro.nix;
      homeModules.starshipwsl = ./homeManagerModules/starshipwsl.nix;
      homeModules.homebasewsl = ./homeManagerModules/homebasewsl.nix;

      formatter.x86_64-linux = treefmtEval.config.build.wrapper;

      checks.x86_64-linux = {
        formatting = treefmtEval.config.build.check self;
      };

      devShells.x86_64-linux.default =
        let
          mkScript =
            name: script:
            pkgs.writeScriptBin name ''
              #!/bin/sh
              ${script}
            '';

          scripts = [
            (mkScript "check" "nix flake check")
            (mkScript "fmt" "nix fmt")

            # Host switch/test scripts
            (mkScript "switch-homebase" "sudo nixos-rebuild switch --flake .#homebase")
            (mkScript "test-homebase" "sudo nixos-rebuild test --flake .#homebase")

            (mkScript "switch-homebase-omarchy" "sudo nixos-rebuild switch --flake .#homebase_omarchy")
            (mkScript "test-homebase-omarchy" "sudo nixos-rebuild test --flake .#homebase_omarchy")

            (mkScript "switch-oldboy" "sudo nixos-rebuild switch --flake .#oldboy")
            (mkScript "test-oldboy" "sudo nixos-rebuild test --flake .#oldboy")

            (mkScript "switch-starshipwsl" "sudo nixos-rebuild switch --flake .#starshipwsl")
            (mkScript "test-starshipwsl" "sudo nixos-rebuild test --flake .#starshipwsl")

            (mkScript "switch-homebasewsl" "sudo nixos-rebuild switch --flake .#homebasewsl")
            (mkScript "test-homebasewsl" "sudo nixos-rebuild test --flake .#homebasewsl")

            (mkScript "switch-nixos" "sudo nixos-rebuild switch --flake .#nixos")
            (mkScript "test-nixos" "sudo nixos-rebuild test --flake .#nixos")

            # Home manager scripts
            (mkScript "switch-home-work" "home-manager switch --flake .#work")
          ];
        in
        pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.nixfmt
            pkgs.treefmt
          ]
          ++ scripts;

          shellHook = ''
            echo "Welcome to the NixOS Config DevShell!"
            echo "Available commands:"
            echo "  check         - Run nix flake check"
            echo "  fmt           - Run nix fmt"
            echo "  switch-<host> - Switch NixOS configuration"
            echo "  test-<host>   - Test NixOS configuration"
            echo ""
            echo "Hosts: homebase, homebase_omarchy, oldboy, starshipwsl, homebasewsl, nixos"
            echo "Home Configs: work"
          '';
        };
    };
}

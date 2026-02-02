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
    mangowc = {
      url = "github:DreamMaoMao/mangowc";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fromscratch = {
      url = "github:Sammyalhashe/fromscratch";
      inputs.nixpkgs.follows = "nixpkgs";
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
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plugin-coding = {
      url = "github:openclaw/skills?dir=skills/steipete/coding-agent";
      flake = false;
    };
    plugin-git = {
      url = "github:openclaw/skills?dir=skills/arnarsson/git-essentials";
      flake = false;
    };
    plugin-docker = {
      url = "github:openclaw/skills?dir=skills/arnarsson/docker-essentials";
      flake = false;
    };
    plugin-system = {
      url = "github:openclaw/skills?dir=skills/zerofire03/system-monitor";
      flake = false;
    };
    plugin-filesystem = {
      url = "github:openclaw/skills?dir=skills/gtrusler/clawdbot-filesystem";
      flake = false;
    };
    plugin-process = {
      url = "github:openclaw/skills?dir=skills/dbhurley/process-watch";
      flake = false;
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
      mangowc,
      fromscratch,
      nixos-wsl,
      stylix,
      treefmt-nix,
      nur,
      sops-nix,
      nixos-hardware,
      nix-openclaw,
      plugin-coding,
      plugin-git,
      plugin-docker,
      plugin-system,
      plugin-filesystem,
      plugin-process,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      overlays = [
        nur.overlays.default
        nix-openclaw.overlays.default
        (final: prev: {
          openclaw-gateway = prev.openclaw-gateway.overrideAttrs (old: {
            installPhase = ''
              ${old.installPhase}
              cp -r docs $out/lib/openclaw/
            '';
          });
          openclaw = prev.openclaw.override {
            openclaw-gateway = final.openclaw-gateway;
          };
        })
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
      nixosConfigurations.filestore = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs sops-nix; };
        system = "aarch64-linux";
        modules = [
          baseConfig
          nixos-hardware.nixosModules.raspberry-pi-4
          ./hosts/filestore/configuration.nix
          ./nixosModules
          stylix.nixosModules.stylix
          ./nixosModules/stylix.nix
          sops-nix.nixosModules.sops
          {
            programs.stylix.enable = true;
            host.isHeadless = true;
          }
        ];
      };

      nixosConfigurations.homebase = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs sops-nix; };
        modules = [
          baseConfig
          ./hosts/homebase/configuration.nix
          ./nixosModules
          stylix.nixosModules.stylix
          ./nixosModules/stylix.nix
          mangowc.nixosModules.mango
          sops-nix.nixosModules.sops
          { programs.stylix.enable = true; }
        ];
      };

      nixosConfigurations.homebase_omarchy = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs sops-nix; };
        modules = [
          baseConfig
          ./hosts/homebase/configuration.nix
          ./nixosModules
          omarchy-nix.nixosModules.default
          stylix.nixosModules.stylix
          ./nixosModules/stylix.nix
          mangowc.nixosModules.mango
          sops-nix.nixosModules.sops
          {
            host.useOmarchy = true;
            host.isWsl = true; # As per original config comment "just to not import the desktop file"
            programs.stylix.enable = true;
          }
        ];
      };

      nixosConfigurations.oldboy = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs sops-nix; };
        modules = [
          baseConfig
          ./hosts/oldboy/configuration.nix
          ./nixosModules
          omarchy-nix.nixosModules.default
          stylix.nixosModules.stylix
          ./nixosModules/stylix.nix
          sops-nix.nixosModules.sops
          {
            host.useOmarchy = true;
            host.isWsl = true;
            programs.stylix.enable = true;
          }
        ];
      };

      nixosConfigurations.starshipwsl = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs sops-nix; };
        inherit system;
        modules = [
          baseConfig
          nixos-wsl.nixosModules.default
          ./hosts/starshipwsl/configuration.nix
          ./nixosModules
          ./nixosModules/wsl.nix
          sops-nix.nixosModules.sops
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
        specialArgs = { inherit inputs sops-nix; };
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
          sops-nix.nixosModules.sops
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

      nixosConfigurations.starship = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs sops-nix; };
        modules = [
          baseConfig
          ./hosts/starship/configuration.nix
          ./nixosModules
          omarchy-nix.nixosModules.default
          stylix.nixosModules.stylix
          ./nixosModules/stylix.nix
          mangowc.nixosModules.mango
          sops-nix.nixosModules.sops
          {
            host.useOmarchy = true;
            host.isWsl = true; # As per original config comment "just to not import the desktop file"
            programs.stylix.enable = true;
          }
        ];
      };

      darwinConfigurations.Sammys-MacBook-Pro = darwin.lib.darwinSystem {
        specialArgs = { inherit inputs sops-nix; };
        system = "x86_64-darwin";
        modules = [
          baseConfig
          ./hosts/Sammys-MacBook-Pro/configuration.nix
          ./nixosModules/options.nix
          sops-nix.darwinModules.sops
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
          inherit inputs sops-nix;
          user = "salhashemi2";
          homeDir = "/root";
        };
        modules = [
          baseConfig
          stylix.homeModules.stylix
          sops-nix.homeManagerModules.sops
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
      homeModules.filestore = ./homeManagerModules/filestore.nix;

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

          mkHostScript =
            name: flakeAttr: hostname: action:
            pkgs.writeScriptBin name ''
              #!/bin/sh
              CURRENT_HOST=$(hostname)
              TARGET_HOST="${hostname}"

              if [ "$CURRENT_HOST" != "$TARGET_HOST" ]; then
                echo "⚠️  WARNING: Current host ($CURRENT_HOST) does not match target host ($TARGET_HOST)."
                printf "Are you sure you want to proceed? [y/N] "
                read -r response
                case "$response" in
                  [yY][eE][sS]|[yY])
                      ;;
                  *)
                      echo "Aborted."
                      exit 1
                      ;;
                esac
              fi

              echo "🚀 Running: sudo nixos-rebuild ${action} --flake .#${flakeAttr}"
              sudo nixos-rebuild ${action} --flake .#${flakeAttr}
            '';

          scripts = [
            (mkScript "check" "nix flake check")
            (mkScript "fmt" "nix fmt")

            # Host switch/test scripts
            (mkHostScript "switch-homebase" "homebase" "homebase" "switch")
            (mkHostScript "test-homebase" "homebase" "homebase" "test")

            (mkHostScript "switch-homebase-omarchy" "homebase_omarchy" "homebase" "switch")
            (mkHostScript "test-homebase-omarchy" "homebase_omarchy" "homebase" "test")

            (mkHostScript "switch-oldboy" "oldboy" "oldboy" "switch")
            (mkHostScript "test-oldboy" "oldboy" "oldboy" "test")

            (mkHostScript "switch-starshipwsl" "starshipwsl" "starship_wsl" "switch")
            (mkHostScript "test-starshipwsl" "starshipwsl" "starship_wsl" "test")

            (mkHostScript "switch-homebasewsl" "homebasewsl" "nixos" "switch")
            (mkHostScript "test-homebasewsl" "homebasewsl" "nixos" "test")

            (mkHostScript "switch-starship" "starship" "starship" "switch")
            (mkHostScript "test-starship" "starship" "starship" "test")

            (mkHostScript "switch-filestore" "filestore" "filestore" "switch")
            (mkHostScript "test-filestore" "filestore" "filestore" "test")

            # Home manager scripts
            (mkScript "switch-home-work" "home-manager switch --flake .#work")
          ];
        in
        pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.nixfmt
            pkgs.treefmt
            pkgs.sops
            pkgs.age
            pkgs.ssh-to-age
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
            echo "Hosts: homebase, homebase_omarchy, oldboy, starshipwsl, homebasewsl, starship, filestore"
            echo "Home Configs: work"
          '';
        };
    };
}

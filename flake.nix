{
  description = "Sammy Al Hashemi's multi-host NixOS & Darwin configuration flake";

  # --- INPUTS: External dependencies and specialized toolsets ---
  inputs = {
    # Main NixOS unstable branch for the latest software and ROCm 7.x support
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    # User-level environment management
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # MacOS configuration management — tracking nix-darwin unstable to match nixpkgs-unstable
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Determinate Nix system management
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    hyprlock.url = "github:hyprwm/hyprlock";

    # Custom Window Managers and UI frameworks
    mangowc = {
      url = "github:DreamMaoMao/mangowc";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fromscratch = {
      url = "github:Sammyalhashe/fromscratch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim.url = "github:Sammyalhashe/nixvim";

    # Homebase Manager (Custom dashboard/management tool)
    homebase-manager = {
      url = "github:Sammyalhashe/homebase-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # WSL2 Integration for Windows
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    # Theming and secrets management
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware-specific optimizations (RPi4, Laptops, etc.)
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Flatpak and XR Driver support
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    # Utilities
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "github:nix-community/NUR";

    # llm
    llama-cpp.url = "github:ggml-org/llama.cpp";

    # mcp
    mcp-hub.url = "github:ravitemer/mcp-hub";

    # AI skills and agents
    ai-skills = {
      url = "github:Sammyalhashe/skills";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Todo CLI with SQLite/MariaDB backend
    todo = {
      url = "github:Sammyalhashe/simple-zig-todo-sqlite";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent.url = "github:NousResearch/hermes-agent/v2026.6.5";

    vicinae.url = "github:vicinaehq/vicinae";
    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    keybr-tui.url = "github:y0sif/keybr-tui";
    nix-snapd = {
      url = "github:nix-community/nix-snapd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      hyprlock,
      mangowc,
      fromscratch,
      nixos-wsl,
      stylix,
      treefmt-nix,
      nur,
      sops-nix,
      nixos-hardware,
      flake-utils,
      llama-cpp,
      mcp-hub,
      ai-skills,
      todo,
      hermes-agent,
      vicinae,
      vicinae-extensions,
      nix-snapd,
      ...
    }@inputs:
    let
      # Define overlays that should be available on all systems
      overlays = [
        nur.overlays.default
      ];

      # Helper to initialize pkgs for a specific architecture with all overlays applied
      getPkgs =
        system:
        import nixpkgs {
          system = system;
          overlays = overlays;
          config.allowUnfree = true;
        };

      # --- BASE CONFIG: Shared settings across all NixOS hosts ---
      baseConfig = {
        nixpkgs = {
          inherit overlays;
        };
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 7d";
        };
      };

    in
    {

      extra-substituters = [ "https://vicinae.cachix.org" ];
      extra-trusted-public-keys = [ "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc=" ];
      nixosConfigurations.filestore = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs sops-nix; };
        system = "aarch64-linux";
        modules = [
          baseConfig
          nixos-hardware.nixosModules.raspberry-pi-4
          ./hosts/filestore/configuration.nix
          ./modules
          stylix.nixosModules.stylix
          ./modules/theming/stylix.nix
          sops-nix.nixosModules.sops
          {
            programs.stylix.enable = true;
            host.isHeadless = true;
          }
        ];
      };

      nixosConfigurations.homebase = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs sops-nix; };
        pkgs = getPkgs "x86_64-linux";
        system = "x86_64-linux";
        modules = [
          baseConfig
          mangowc.nixosModules.mango
          inputs.nix-flatpak.nixosModules.nix-flatpak
          ./hosts/homebase/configuration.nix
          ./modules
          stylix.nixosModules.stylix
          ./modules/theming/stylix.nix
          sops-nix.nixosModules.sops
          nix-snapd.nixosModules.default
          {
            host.enableMango = false;
            host.enableHyprland = false;
            host.setNameservers = true;
          }
        ];
      };

      nixosConfigurations.mothership = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs sops-nix; };
        pkgs = getPkgs "x86_64-linux";
        modules = [
          baseConfig
          mangowc.nixosModules.mango
          inputs.nix-flatpak.nixosModules.nix-flatpak
          ./hosts/mothership/configuration.nix
          ./modules
          stylix.nixosModules.stylix
          ./modules/theming/stylix.nix
          sops-nix.nixosModules.sops
          nix-snapd.nixosModules.default
          {
            programs.stylix.enable = true;
          }
          (
            { pkgs, ... }:
            {
              nixpkgs.overlays = [ llama-cpp.overlays.default ];
            }
          )
          (
            { pkgs, ... }:
            {
              environment.systemPackages = [
                (pkgs.stdenv.mkDerivation {
                  name = "push-to-cachix";
                  dontUnpack = true;
                  buildInputs = [
                    pkgs.nushell
                    pkgs.sops
                    pkgs.cachix
                  ];
                  installPhase = ''
                    install -Dm755 ${./push-to-cachix.nu} $out/bin/push-to-cachix
                  '';
                })
              ];
              systemd.services.push-to-cachix = {
                description = "Push NixOS configurations to Cachix";
                serviceConfig = {
                  Type = "oneshot";
                  ExecStart = "${pkgs.nushell}/bin/nu ${./push-to-cachix.nu}";
                  User = "root"; # Or a specific user if needed, but root is usually safer for nix build
                };
                path = [
                  pkgs.nix
                  pkgs.sops
                  pkgs.cachix
                  pkgs.git
                  pkgs.nushell
                ];
              };
              systemd.timers.push-to-cachix = {
                wantedBy = [ "timers.target" ];
                timerConfig = {
                  OnCalendar = "weekly";
                  Persistent = true;
                };
              };
            }
          )
        ];
      };

      nixosConfigurations.oldboy = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs sops-nix; };
        system = "x86_64-linux";
        pkgs = getPkgs "x86_64-linux";
        modules = [
          baseConfig
          ./hosts/oldboy/configuration.nix
          ./modules
          ./modules/ai/hermes/hermes.nix
          hermes-agent.nixosModules.default
          sops-nix.nixosModules.sops
          nix-snapd.nixosModules.default
          {
            host.isHeadless = true;
          }
        ];
      };

      nixosConfigurations.starshipwsl = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs sops-nix; };
        system = "x86_64-linux";
        pkgs = getPkgs "x86_64-linux";
        modules = [
          baseConfig
          mangowc.nixosModules.mango
          nixos-wsl.nixosModules.default
          ./hosts/starshipwsl/configuration.nix
          ./modules
          ./modules/wsl
          sops-nix.nixosModules.sops
          {
            environments.wsl.enable = true;
          }
          stylix.nixosModules.stylix
          ./modules/theming/stylix.nix
          {
            programs.stylix.enable = true;
          }
        ];
      };

      nixosConfigurations.homebasewsl = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs sops-nix; };
        pkgs = getPkgs "x86_64-linux";
        system = "x86_64-linux";
        modules = [
          baseConfig
          mangowc.nixosModules.mango
          {
            nixpkgs.overlays = [
              (final: prev: {
                wrapGAppsHook = prev.wrapGAppsHook3;
              })
            ];
          }
          nixos-wsl.nixosModules.default
          ./hosts/homebasewsl/configuration.nix
          ./modules
          ./modules/wsl
          sops-nix.nixosModules.sops
          {
            environments.wsl.enable = true;
          }
          stylix.nixosModules.stylix
          ./modules/theming/stylix.nix
          {
            programs.stylix.enable = true;
          }
        ];
      };

      nixosConfigurations.starship = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs sops-nix; };
        system = "x86_64-linux";
        pkgs = getPkgs "x86_64-linux";
        modules = [
          baseConfig
          mangowc.nixosModules.mango
          inputs.nix-flatpak.nixosModules.nix-flatpak
          ./hosts/starship/configuration.nix
          ./modules
          stylix.nixosModules.stylix
          ./modules/theming/stylix.nix
          sops-nix.nixosModules.sops
          nix-snapd.nixosModules.default
          {
            host.enableKDE = true;
            host.enableMango = true;
            host.enableHyprland = false;
            programs.stylix.enable = true;
            host.enableCloudflareWarp = true;
          }
        ];
      };

      # Home-manager module mappings for different host types
      homeModules.default = ./homeManagerModules;
      homeModules.starship = ./homeManagerModules;
      homeModules.starshipwsl = ./homeManagerModules/starshipwsl.nix;
      homeModules.homebasewsl = ./homeManagerModules/homebasewsl.nix;
      homeModules.filestore = ./homeManagerModules/filestore.nix;
      homeModules.mothership = ./homeManagerModules/mothership.nix;
      homeModules.server = ./homeManagerModules/server.nix;
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = getPkgs system;
        treefmtEval = treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
        };
      in
      {
        formatter = treefmtEval.config.build.wrapper;

        checks = {
          formatting = treefmtEval.config.build.check self;
        };

        devShells.default =
          let
            inherit (import ./common/utils/devshellFuncs.nix { inherit pkgs; })
              mkScript
              mkHostScript
              mkDeployScript
              mkBuildAllScript
              mkEvalAllScript
              buildTargets
              hosts
              ;

            # Per-host build/eval convenience scripts (build-<host>, eval-<host>).
            perHostScripts = builtins.concatMap (host: [
              (mkScript "build-${host}" "nix build .#nixosConfigurations.${host}.config.system.build.toplevel --no-link")
              (mkScript "eval-${host}" "nix eval .#nixosConfigurations.${host}.config.system.build.toplevel.drvPath --raw")
            ]) hosts;

            scripts = [
              (mkScript "check" "nix flake check")
              (mkScript "fmt" "nix fmt")

              # Attempt to build the top-level of every host
              (mkBuildAllScript "buildX" buildTargets)

              # Attempt to evaluate (not build) the top-level of every host
              (mkEvalAllScript "checkX" buildTargets)

              # Push to cachix scripts
              (mkScript "push-all" "${pkgs.nushell}/bin/nu ${./push-to-cachix.nu}")
              (mkScript "push-mothership" "${pkgs.nushell}/bin/nu ${./push-to-cachix.nu} mothership")
              (mkScript "push-homebase" "${pkgs.nushell}/bin/nu ${./push-to-cachix.nu} homebase")
              (mkScript "push-starship" "${pkgs.nushell}/bin/nu ${./push-to-cachix.nu} starship")
              (mkScript "push-starshipwsl" "${pkgs.nushell}/bin/nu ${./push-to-cachix.nu} starshipwsl")
              (mkScript "push-oldboy" "${pkgs.nushell}/bin/nu ${./push-to-cachix.nu} oldboy")

              # Host switch/test scripts
              (mkHostScript "switch-homebase" "homebase" "homebase" "switch")
              (mkHostScript "test-homebase" "homebase" "homebase" "test")

              (mkHostScript "switch-mothership" "mothership" "mothership" "switch")
              (mkHostScript "test-mothership" "mothership" "mothership" "test")

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

              # Remote deploy scripts (build locally, push + activate on remote host)
              # Usage: deploy-<host> [switch|test|boot|dry-activate]
              (mkDeployScript "deploy-homebase" "homebase" "homebase")
              (mkDeployScript "deploy-starship" "starship" "starship")
              (mkDeployScript "deploy-oldboy" "oldboy" "oldboy")
              (mkDeployScript "deploy-filestore" "filestore" "filestore")
              (mkDeployScript "deploy-starshipwsl" "starshipwsl" "starship_wsl")

            ]
            ++ perHostScripts;
          in
          pkgs.mkShell {
            nativeBuildInputs = [
              pkgs.nixfmt
              pkgs.treefmt
              pkgs.sops
              pkgs.age
              pkgs.ssh-to-age
              pkgs.cachix
              pkgs.jq
            ]
            ++ scripts;

            shellHook = ''
              echo "Welcome to the NixOS Config DevShell!"
              echo "Available commands:"
                          echo "  check         - Run nix flake check"
                          echo "  fmt           - Run nix fmt"
                          echo "  buildX        - Attempt to build the top-level of every host"
                          echo "  checkX        - Attempt to evaluate the top-level of every host"
                          echo "  push-homebase    - Build homebase system config and push to cachix"
                                      echo "  push-starship    - Build starship system config and push to cachix"
                                      echo "  push-starshipwsl - Build starshipwsl system config and push to cachix"
                                      echo "  push-mothership - Build mothership system config and push to cachix"
                                      echo "  deploy-<host> [action] - Build locally, push and activate on remote host (default: switch)"
              echo "  switch-<host>    - Switch NixOS configuration locally"
              echo "  test-<host>      - Test NixOS configuration locally"
              echo "  build-<host>     - Build a single host's top-level"
              echo "  eval-<host>      - Evaluate a single host's top-level (no build)"
              echo ""
              echo "Hosts: homebase, oldboy, starshipwsl, homebasewsl, starship, filestore, mothership"
            '';
          };
      }
    );
}

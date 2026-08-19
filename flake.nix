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

    # Remote NixOS deployment (build locally, push + activate with rollback)
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
    };

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

    # Self-hosted TRMNL server (terminus) as a podman OCI module
    terminus = {
      url = "github:Sammyalhashe/terminus-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    llm-agents.url = "github:numtide/llm-agents.nix";

    kaspa-ng = {
      url = "github:aspectron/kaspa-ng";
      flake = false;
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
      nix-cachyos-kernel,
      llm-agents,
      kaspa-ng,
      ...
    }@inputs:
    let
      # Define overlays that should be available on all systems
      overlays = [
        nur.overlays.default
        llm-agents.overlays.shared-nixpkgs
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
        # Binary cache for the vicinae launcher (avoids compiling it from source).
        nix.settings.extra-substituters = [
          "https://vicinae.cachix.org"
          "https://cache.numtide.com"
        ];
        nix.settings.extra-trusted-public-keys = [
          "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        ];
        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 7d";
        };
      };

      # Modules shared by every host.
      commonModules = [
        baseConfig
        ./modules
        sops-nix.nixosModules.sops
      ];

      # Stylix theming, opted into per-host (see `modules`).
      stylixModules = [
        stylix.nixosModules.stylix
        ./modules/theming/stylix.nix
      ];

      # Factory for a NixOS host: assembles the common modules with the host's
      # own configuration and any extra modules it needs.
      mkHost =
        {
          name,
          system ? "x86_64-linux",
          modules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs sops-nix; };
          pkgs = getPkgs system;
          modules = commonModules ++ [ ./hosts/${name}/configuration.nix ] ++ modules;
        };

      # Shared host table (hostname -> { ip, hostname, system }): single source
      # of truth for deploy-rs nodes and the devshell per-host scripts.
      hostsData = import ./hosts.nix;

    in
    {

      nixosConfigurations.filestore = mkHost {
        name = "filestore";
        system = "aarch64-linux";
        modules = stylixModules ++ [
          nixos-hardware.nixosModules.raspberry-pi-4
          {
            programs.stylix.enable = true;
            host.isHeadless = true;
          }
        ];
      };

      nixosConfigurations.homebase = mkHost {
        name = "homebase";
        modules = stylixModules ++ [
          mangowc.nixosModules.mango
          inputs.nix-flatpak.nixosModules.nix-flatpak
          {
            host.enableMango = false;
            host.enableHyprland = false;
            host.setNameservers = true;
          }
          (
            { pkgs, ... }:
            {
              nixpkgs.overlays = [
                nix-cachyos-kernel.overlays.pinned
              ];
              boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
            }
          )
        ];
      };

      nixosConfigurations.mothership = mkHost {
        name = "mothership";
        modules = stylixModules ++ [
          mangowc.nixosModules.mango
          inputs.nix-flatpak.nixosModules.nix-flatpak
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
                  # push-to-cachix.nu uses relative paths (`nix build .#...`,
                  # `sops -d secrets.yaml`), so run it from the flake checkout.
                  WorkingDirectory = "/home/salhashemi2/nixosConfig";
                  # Let sops decrypt secrets.yaml with mothership's host key.
                  Environment = "SOPS_AGE_SSH_PRIVATE_KEY_FILE=/etc/ssh/ssh_host_ed25519_key";
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

      nixosConfigurations.oldboy = mkHost {
        name = "oldboy";
        modules = [
          ./modules/ai/hermes/hermes.nix
          hermes-agent.nixosModules.default
          {
            host.isHeadless = true;
          }
        ];
      };

      nixosConfigurations.starshipwsl = mkHost {
        name = "starshipwsl";
        modules = stylixModules ++ [
          mangowc.nixosModules.mango
          nixos-wsl.nixosModules.default
          ./modules/wsl
          {
            environments.wsl.enable = true;
          }
          {
            programs.stylix.enable = true;
          }
        ];
      };

      nixosConfigurations.homebasewsl = mkHost {
        name = "homebasewsl";
        modules = stylixModules ++ [
          mangowc.nixosModules.mango
          {
            nixpkgs.overlays = [
              (final: prev: {
                wrapGAppsHook = prev.wrapGAppsHook3;
              })
            ];
          }
          nixos-wsl.nixosModules.default
          ./modules/wsl
          {
            environments.wsl.enable = true;
          }
          {
            programs.stylix.enable = true;
          }
        ];
      };

      nixosConfigurations.starship = mkHost {
        name = "starship";
        modules = stylixModules ++ [
          mangowc.nixosModules.mango
          inputs.nix-flatpak.nixosModules.nix-flatpak
          {
            host.enableKDE = true;
            host.enableMango = true;
            host.enableHyprland = false;
            programs.stylix.enable = true;
            host.enableCloudflareWarp = true;
          }
        ];
      };

      homeConfigurations.ryoku = home-manager.lib.homeManagerConfiguration {
        pkgs = getPkgs "x86_64-linux";
        extraSpecialArgs = {
          inherit inputs sops-nix;
          user = "salhashemi2";
          homeDir = "/home/salhashemi2";
        };
        modules = [
          baseConfig
          sops-nix.homeManagerModules.sops
          ./homeManagerModules/ryoku.nix
          ./common/home-ryoku.nix
          ./homeManagerModules/cloudflare-warp.nix
          {
            environments.wsl = {
              enable = false;
            };
            networking.cloudflare-warp.enable = true;
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

      # deploy-rs targets (build locally, copy over SSH, activate w/ rollback).
      # Node definitions live in ./deploy.nix; run `deploy .#<host>`.
      deploy = import ./deploy.nix {
        inherit self inputs;
        hosts = hostsData;
      };
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
        }
        # deploy-rs' activation checks build each node's full system closure,
        # which can't cross-compile from this machine (Linux nodes on Darwin,
        # or the other arch from one Linux host). Keep only the arch-neutral
        # schema check so `nix flake check` works everywhere; activation is
        # verified by deploy-rs at deploy time.
        // pkgs.lib.filterAttrs (name: _: pkgs.lib.hasInfix "schema" name) (
          inputs.deploy-rs.lib.${system}.deployChecks self.deploy
        );

        devShells.default =
          let
            inherit
              (import ./common/utils/devshellFuncs.nix {
                inherit pkgs;
                hosts = hostsData;
              })
              mkScript
              mkHostScript
              mkBuildAllScript
              mkEvalAllScript
              buildTargets
              hosts
              hostNames
              pushHosts
              ;

            # switch-<host> / test-<host> for every host (with hostname guard).
            hostScripts = builtins.concatMap (host: [
              (mkHostScript "switch-${host}" host hostNames.${host} "switch")
              (mkHostScript "test-${host}" host hostNames.${host} "test")
            ]) hosts;

            # Per-host build/eval convenience scripts (build-<host>, eval-<host>).
            perHostScripts = builtins.concatMap (host: [
              (mkScript "build-${host}" "nix build .#nixosConfigurations.${host}.config.system.build.toplevel --no-link")
              (mkScript "eval-${host}" "nix eval .#nixosConfigurations.${host}.config.system.build.toplevel.drvPath --raw")
            ]) hosts;

            # push-<host> cachix scripts.
            pushScripts = map (
              host: mkScript "push-${host}" "${pkgs.nushell}/bin/nu ${./push-to-cachix.nu} ${host}"
            ) pushHosts;

            scripts = [
              (mkScript "check" "nix flake check")
              (mkScript "fmt" "nix fmt")

              # Attempt to build the top-level of every host
              (mkBuildAllScript "buildX" buildTargets)

              # Attempt to evaluate (not build) the top-level of every host
              (mkEvalAllScript "checkX" buildTargets)

              # Push all hosts to cachix
              (mkScript "push-all" "${pkgs.nushell}/bin/nu ${./push-to-cachix.nu}")

              # Remote deploys are handled by deploy-rs: `deploy .#<host>`
            ]
            ++ hostScripts
            ++ pushScripts
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
              inputs.deploy-rs.packages.${system}.default
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
                                      echo "  deploy .#<host>  - Deploy (build locally, push + activate w/ rollback) via deploy-rs"
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

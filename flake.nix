{
  description = "Sammy Al Hashemi's multi-host NixOS & Darwin configuration flake";

  # --- INPUTS: External dependencies and specialized toolsets ---
  inputs = {
    # Main NixOS unstable branch for the latest software and ROCm 7.x support
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    
    # User-level environment management
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # MacOS configuration management
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Specialized browsers and UI tools
    zen-browser = {
      url = "github:Sammyalhashe/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware-specific optimizations (RPi4, Laptops, etc.)
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    
    # OpenClaw Agent and Picoclaw Tooling
    nix-picoclaw = {
      url = "github:Sammyalhashe/picoclaw";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Flatpak and XR Driver support
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    viture-virtual-display = {
      url = "github:mgschwan/viture_virtual_display";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    breezy-desktop = {
      url = "path:./breezy_src";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Utilities
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "github:nix-community/NUR";

    # OpenClaw Skills (Modular AI capabilities)
    plugin-coding = { url = "github:openclaw/skills?dir=skills/steipete/coding-agent"; flake = false; };
    plugin-git = { url = "github:openclaw/skills?dir=skills/arnarsson/git-essentials"; flake = false; };
    plugin-docker = { url = "github:openclaw/skills?dir=skills/arnarsson/docker-essentials"; flake = false; };
    plugin-system = { url = "github:openclaw/skills?dir=skills/zerofire03/system-monitor"; flake = false; };
    plugin-filesystem = { url = "github:openclaw/skills?dir=skills/gtrusler/clawdbot-filesystem"; flake = false; };
    plugin-process = { url = "github:openclaw/skills?dir=skills/dbhurley/process-watch"; flake = false; };
    plugin-polyclaw = { url = "github:openclaw/skills?dir=skills/akegaviar/polyclaw"; flake = false; };
    plugin-better-memory = { url = "github:openclaw/skills?dir=skills/dvntydigital/better-memory"; flake = false; };
    plugin-email = { url = "github:openclaw/skills?dir=skills/gzlicanyi/imap-smtp-email"; flake = false; };
    plugin-cloudflare = { url = "github:openclaw/skills?dir=skills/stopmoclay/cloudflare-api"; flake = false; };

    # llm
    llama-cpp.url = "github:ggml-org/llama.cpp";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      darwin,
      zen-browser,
      hyprlock,
      mangowc,
      fromscratch,
      nixos-wsl,
      stylix,
      treefmt-nix,
      nur,
      sops-nix,
      nixos-hardware,
      nix-openclaw,
      nix-picoclaw,
      plugin-coding,
      plugin-git,
      plugin-docker,
      plugin-system,
      plugin-filesystem,
      plugin-process,
      plugin-polyclaw,
      plugin-better-memory,
      plugin-email,
      plugin-cloudflare,
      flake-utils,
      llama-cpp,
      ...
    }@inputs:
    let
      # Define overlays that should be available on all systems
      overlays = [
        nur.overlays.default
        nix-openclaw.overlays.default
        nix-picoclaw.overlays.default
        (final: prev: {
          openclaw-gateway = prev.openclaw-gateway.overrideAttrs (old: {
            installPhase = ''
              ${old.installPhase}
              cp -r docs $out/lib/openclaw/
              # Fix for missing plugin manifests in dist/extensions
              if [ -d "$out/lib/openclaw/extensions" ]; then
                find "$out/lib/openclaw/extensions" -name "openclaw.plugin.json" | while read manifest; do
                  plugin_name=$(basename $(dirname "$manifest"))
                  target_dir="$out/lib/openclaw/dist/extensions/$plugin_name"
                  if [ -d "$target_dir" ]; then
                    cp "$manifest" "$target_dir/"
                  fi
                done
              fi
            '';
          });
          openclaw = prev.openclaw.override {
            openclaw-gateway = final.openclaw-gateway;
          };
        })
      ];

      # Helper to initialize pkgs for a specific architecture with all overlays applied
      getPkgs = system: import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };

      # --- BASE CONFIG: Shared settings across all NixOS hosts ---
      baseConfig = {
        nixpkgs = {
          inherit overlays;
          config.allowUnfree = true;
        };
        nix.settings.experimental-features = [ "nix-command" "flakes" ];
        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 7d";
        };
      };
    in
    {
      nixosConfigurations.filestore = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs sops-nix; };
        stdenv.hostPlatform.system = "aarch64-linux";
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
          {
            programs.stylix.enable = true;
          }
        ];
      };

      nixosConfigurations.mothership = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs sops-nix; };
        system = "x86_64-linux";
        modules = [
          baseConfig
          mangowc.nixosModules.mango
          inputs.nix-flatpak.nixosModules.nix-flatpak
          ./hosts/mothership/configuration.nix
          ./modules
          stylix.nixosModules.stylix
          ./modules/theming/stylix.nix
          sops-nix.nixosModules.sops
          {
            host.enableKDE = true;
            host.enableMango = true;
            programs.stylix.enable = true;
          }
          (
            { pkgs, ... }:
            {
              nixpkgs.overlays = [ llama-cpp.overlays.default ];
            }
          )
        ];
      };

      nixosConfigurations.oldboy = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs sops-nix; };
        system = "x86_64-linux";
        modules = [
          baseConfig
          ./hosts/oldboy/configuration.nix
          ./modules
          sops-nix.nixosModules.sops
          {
            host.isHeadless = true;
          }
        ];
      };

      nixosConfigurations.starshipwsl = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs sops-nix; };
        system = "x86_64-linux";
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
        modules = [
          baseConfig
          mangowc.nixosModules.mango
          inputs.nix-flatpak.nixosModules.nix-flatpak
          ./hosts/starship/configuration.nix
          ./modules
          stylix.nixosModules.stylix
          ./modules/theming/stylix.nix
          sops-nix.nixosModules.sops
          {
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
          ./modules/options.nix
          sops-nix.darwinModules.sops
        ];
      };

      # Home-manager-only config for work
      homeConfigurations.work = home-manager.lib.homeManagerConfiguration {
        # inherit pkgs; # <--- Removing this to define nixpkgs explicitly
        pkgs = getPkgs "x86_64-linux";
        extraSpecialArgs = {
          inherit inputs sops-nix;
          user = "salhashemi2";
          homeDir = "/root";
        };
        modules = [
          baseConfig
          sops-nix.homeManagerModules.sops
          ./homeManagerModules/work.nix
          ./common/home-work.nix
        ];
      };

      # Home-manager module mappings for different host types
      homeModules.default = ./homeManagerModules;
      homeModules.Sammys-MacBook-Pro = ./homeManagerModules/Sammys-MacBook-Pro.nix;
      homeModules.starshipwsl = ./homeManagerModules/starshipwsl.nix;
      homeModules.homebasewsl = ./homeManagerModules/homebasewsl.nix;
      homeModules.filestore = ./homeManagerModules/filestore.nix;
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

              # Home manager scripts
              (mkScript "switch-home-work" "home-manager switch --flake .#work")
              (mkScript "push-work" ''
                if [ -z "''${CACHIX_AUTH_TOKEN}" ]; then
                  export CACHIX_AUTH_TOKEN=$(sops -d --extract '["cachix_token"]' secrets.yaml)
                fi

                if [ -z "''${CACHIX_AUTH_TOKEN}" ]; then
                  echo "Error: Could not retrieve CACHIX_AUTH_TOKEN from secrets.yaml"
                  exit 1
                fi

                echo "Building work home configuration..."
                OUT_PATH=$(nix build .#homeConfigurations.work.activationPackage --json | jq -r '.[].outputs.out')

                if [ -z "''${OUT_PATH}" ]; then
                  echo "Error: Build failed or produced no output."
                  exit 1
                fi

                echo "Pushing ''${OUT_PATH} to cachix..."
                cachix push starllama "''${OUT_PATH}"
              '')
              (mkScript "push-homebase" ''
                if [ -z "''${CACHIX_AUTH_TOKEN}" ]; then
                  export CACHIX_AUTH_TOKEN=$(sops -d --extract '["cachix_token"]' secrets.yaml)
                fi

                if [ -z "''${CACHIX_AUTH_TOKEN}" ]; then
                  echo "Error: Could not retrieve CACHIX_AUTH_TOKEN from secrets.yaml"
                  exit 1
                fi

                echo "Building homebase system configuration..."
                OUT_PATH=$(nix build .#nixosConfigurations.homebase.config.system.build.toplevel --json | jq -r '.[].outputs.out')

                if [ -z "''${OUT_PATH}" ]; then
                  echo "Error: Build failed or produced no output."
                  exit 1
                fi

                echo "Pushing ''${OUT_PATH} to cachix..."
                cachix push starllama "''${OUT_PATH}"
              '')
              (mkScript "push-mothership" ''
                if [ -z "''${CACHIX_AUTH_TOKEN}" ]; then
                  export CACHIX_AUTH_TOKEN=$(sops -d --extract '["cachix_token"]' secrets.yaml)
                fi

                if [ -z "''${CACHIX_AUTH_TOKEN}" ]; then
                  echo "Error: Could not retrieve CACHIX_AUTH_TOKEN from secrets.yaml"
                  exit 1
                fi

                echo "Building mothership system configuration..."
                OUT_PATH=$(nix build .#nixosConfigurations.mothership.config.system.build.toplevel --json | jq -r '.[].outputs.out')

                if [ -z "''${OUT_PATH}" ]; then
                  echo "Error: Build failed or produced no output."
                  exit 1
                fi

                echo "Pushing ''${OUT_PATH} to cachix..."
                cachix push starllama "''${OUT_PATH}"
              '')
              (mkScript "push-starship" ''
                if [ -z "''${CACHIX_AUTH_TOKEN}" ]; then
                  export CACHIX_AUTH_TOKEN=$(sops -d --extract '["cachix_token"]' secrets.yaml)
                fi

                if [ -z "''${CACHIX_AUTH_TOKEN}" ]; then
                  echo "Error: Could not retrieve CACHIX_AUTH_TOKEN from secrets.yaml"
                  exit 1
                fi

                echo "Building starship system configuration..."
                OUT_PATH=$(nix build .#nixosConfigurations.starship.config.system.build.toplevel --json | jq -r '.[].outputs.out')

                if [ -z "''${OUT_PATH}" ]; then
                  echo "Error: Build failed or produced no output."
                  exit 1
                fi

                echo "Pushing ''${OUT_PATH} to cachix..."
                cachix push starllama "''${OUT_PATH}"
              '')
              (mkScript "push-starshipwsl" ''
                if [ -z "''${CACHIX_AUTH_TOKEN}" ]; then
                  export CACHIX_AUTH_TOKEN=$(sops -d --extract '["cachix_token"]' secrets.yaml)
                fi

                if [ -z "''${CACHIX_AUTH_TOKEN}" ]; then
                  echo "Error: Could not retrieve CACHIX_AUTH_TOKEN from secrets.yaml"
                  exit 1
                fi

                echo "Building starshipwsl system configuration..."
                OUT_PATH=$(nix build .#nixosConfigurations.starshipwsl.config.system.build.toplevel --json | jq -r '.[].outputs.out')

                if [ -z "''${OUT_PATH}" ]; then
                  echo "Error: Build failed or produced no output."
                  exit 1
                fi

                echo "Pushing ''${OUT_PATH} to cachix..."
                cachix push starllama "''${OUT_PATH}"
              '')
              (mkScript "push-filestore" ''
                if [ -z "''${CACHIX_AUTH_TOKEN}" ]; then
                  export CACHIX_AUTH_TOKEN=$(sops -d --extract '["cachix_token"]' secrets.yaml)
                fi

                if [ -z "''${CACHIX_AUTH_TOKEN}" ]; then
                  echo "Error: Could not retrieve CACHIX_AUTH_TOKEN from secrets.yaml"
                  exit 1
                fi

                echo "Building filestore system configuration..."
                OUT_PATH=$(nix build .#nixosConfigurations.filestore.config.system.build.toplevel --json | jq -r '.[].outputs.out')

                if [ -z "''${OUT_PATH}" ]; then
                  echo "Error: Build failed or produced no output."
                  exit 1
                fi

                echo "Pushing ''${OUT_PATH} to cachix..."
                cachix push starllama "''${OUT_PATH}"
              '')
            ];
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
                          echo "  push-work     - Build work home config and push to cachix"
                                      echo "  push-homebase    - Build homebase system config and push to cachix"
                                      echo "  push-starship    - Build starship system config and push to cachix"
                                      echo "  push-starshipwsl - Build starshipwsl system config and push to cachix"
                                      echo "  push-mothership - Build mothership system config and push to cachix"
                                      echo "  switch-<host>    - Switch NixOS configuration"              echo "  test-<host>   - Test NixOS configuration"
              echo ""
              echo "Hosts: homebase, oldboy, starshipwsl, homebasewsl, starship, filestore, mothership"
              echo "Home Configs: work"
            '';
          };
      }
    );
}

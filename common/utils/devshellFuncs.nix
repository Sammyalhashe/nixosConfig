{
  pkgs,
}:
let
  # Maps each flake attribute (nixosConfigurations.<attr>) to the machine's
  # actual hostname, used for the safety check in switch/test scripts.
  hostNames = {
    homebase = "homebase";
    mothership = "mothership";
    oldboy = "oldboy";
    starship = "starship";
    starshipwsl = "starship_wsl";
    homebasewsl = "nixos";
    filestore = "filestore";
  };

  # All NixOS hosts defined in this flake.
  hosts = builtins.attrNames hostNames;

  # Hosts that get a cachix push script (push-<host>).
  pushHosts = [
    "mothership"
    "homebase"
    "starship"
    "starshipwsl"
    "oldboy"
  ];
in
{
  inherit hosts hostNames pushHosts;

  # All host configs, as top-level build targets for `buildX` / `checkX`.
  buildTargets = map (host: "nixosConfigurations.${host}.config.system.build.toplevel") hosts;

  mkDarwinScript =
    name: flakeAttr: action:
    pkgs.writeScriptBin name ''
      #!/bin/sh
      echo "Running: darwin-rebuild ${action} --flake .#${flakeAttr}"
      darwin-rebuild ${action} --flake .#${flakeAttr}
    '';

  mkScript =
    name: script:
    pkgs.writeScriptBin name ''
      #!/bin/sh
      ${script}
    '';

  # Attempt to build the top-level of every given flake target, continuing
  # through all targets even if some fail, then report a summary.
  mkBuildAllScript =
    name: targets:
    pkgs.writeScriptBin name ''
      #!/bin/sh
      FAILED=""
      for target in ${pkgs.lib.concatStringsSep " " targets}; do
        echo "🔨 Building .#$target..."
        if nix build ".#$target" --no-link; then
          echo "✅ $target"
        else
          echo "❌ $target"
          FAILED="$FAILED $target"
        fi
      done

      if [ -n "$FAILED" ]; then
        echo "Failed builds:$FAILED"
        exit 1
      fi
      echo "All builds succeeded."
    '';

  # Attempt to evaluate (not build) the top-level of every given flake
  # target, continuing through all targets even if some fail, then report a
  # summary. Useful for checking configs that can't be built natively (e.g.
  # Linux hosts from a Darwin machine).
  mkEvalAllScript =
    name: targets:
    pkgs.writeScriptBin name ''
      #!/bin/sh
      FAILED=""
      for target in ${pkgs.lib.concatStringsSep " " targets}; do
        echo "🔍 Evaluating .#$target..."
        if nix eval ".#$target.drvPath" --raw >/dev/null; then
          echo "✅ $target"
        else
          echo "❌ $target"
          FAILED="$FAILED $target"
        fi
      done

      if [ -n "$FAILED" ]; then
        echo "Failed evaluations:$FAILED"
        exit 1
      fi
      echo "All evaluations succeeded."
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

  mkDeployScript =
    name: flakeAttr: targetHost:
    pkgs.writeScriptBin name ''
      #!/bin/sh
      set -e
      ACTION="''${1:-switch}"

      echo "Building .#nixosConfigurations.${flakeAttr}..."
      OUT_PATH=$(nix build .#nixosConfigurations.${flakeAttr}.config.system.build.toplevel --json --no-link | jq -r '.[].outputs.out')

      if [ -z "''${OUT_PATH}" ]; then
        echo "Error: Build failed or produced no output."
        exit 1
      fi

      echo "Copying closure to ${targetHost}..."
      nix copy --to "ssh-ng://root@${targetHost}" "''${OUT_PATH}"

      echo "Activating ($ACTION) on ${targetHost}..."
      ssh root@${targetHost} "nix-env -p /nix/var/nix/profiles/system --set ''\'''${OUT_PATH}' && ''\'''${OUT_PATH}/bin/switch-to-configuration' '$ACTION'"

      echo "Done deploying to ${targetHost}."
    '';
}

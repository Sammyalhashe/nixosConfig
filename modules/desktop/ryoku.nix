# Ryoku desktop (Hyprland + Quickshell), gated on host.useRyokuDesktop.
#
# BLOCKED, and not by something a lock bump fixes. Ryoku's module sets
# `security.polkit.enablePkexecWrapper`, which does not exist on the nixos-26.05
# release branch this flake tracks — it is an unstable-only option and was never
# backported. Setting an option that does not exist is a structural error the
# module system raises regardless of `lib.mkIf`: the flag being false does not
# help, because mkIf defers a value, not the option's existence. So merely
# importing this file fails evaluation for the importing host.
#
# Confirmed by updating nixpkgs to the newest nixos-26.05 revision
# (21a67dc, 2026-09-11) and re-checking: still absent. Unblocking it means
# moving this flake to nixos-unstable, which would take every host at once —
# a deliberate decision, not a side effect of wiring up a desktop.
#
# That is why this is NOT in modules/desktop/default.nix: putting it there broke
# all seven hosts at once.
#
# TO OPT IN, once nixpkgs is new enough: add it to that host's mkHost modules,
# the same way homebase takes mangowc.nixosModules.mango, and set the flag:
#
#   nixosConfigurations.starship = mkHost {
#     name = "starship";
#     modules = stylixModules ++ [
#       ./modules/desktop/ryoku.nix
#       { host.useRyokuDesktop = true; }
#     ];
#   };
#
# x86_64-linux only: upstream populates only `packages.x86_64-linux` and its
# module resolves `self.packages.${system}`. The assertion below covers that.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.host;
  supported = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
in
{
  imports = [ inputs.ryoku.nixosModules.default ];

  config = lib.mkIf cfg.useRyokuDesktop {
    assertions = [
      {
        assertion = supported;
        message = ''
          host.useRyokuDesktop is enabled on ${pkgs.stdenv.hostPlatform.system},
          but Ryoku only builds for x86_64-linux — its flake hardcodes that
          system, so self.packages has no attribute for this platform.
        '';
      }
    ];

    # Guarded on `supported` as well as on the flag, and that second guard is
    # load-bearing rather than belt-and-braces. Setting this true on an
    # unsupported system pulls in upstream's own config block, which forces
    # ryokuPkgs and dies with a raw `attribute '<system>' missing` *before* the
    # assertion above can report. Leaving it false lets the assertion do its job.
    programs.ryoku.enable = lib.mkIf supported true;
  };
}

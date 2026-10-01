# Ryoku desktop (Hyprland + Quickshell), gated on host.useRyokuDesktop.
#
# Needs nixos-unstable: Ryoku's module sets `security.polkit.enablePkexecWrapper`,
# which nixos-26.05 lacks, and setting an option that does not exist fails
# evaluation even behind `lib.mkIf`. On unstable, importing this file with the
# flag off is a no-op.
#
# Kept out of modules/desktop/default.nix anyway: Ryoku's packages use
# import-from-derivation (importCargoLock reads a Cargo.lock out of a fetched
# x86_64-linux source). Evaluating an enabled host elsewhere (e.g. the Mac)
# fails with "platform mismatch" on that source until it is in the local
# store. It is a plain fixed-output fetch, so adding it by hand is enough:
#
#   nix-prefetch-url --unpack --name source \
#     https://github.com/FrameworkComputer/qmk_hid/archive/<rev>.tar.gz
#
# (<rev> is in the error's .drv: `nix derivation show <drv>`.)
#
# TO OPT IN: add it to that host's mkHost modules,
# the same way homebase takes mangoModule, and set the flag:
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

    # Ryoku sets nixpkgs.config.allowUnfreePredicate (mkDefault), but mkHost
    # passes in a pkgs instance and NixOS asserts nixpkgs.config stays empty in
    # that case. The predicate is moot anyway: getPkgs already has allowUnfree.
    nixpkgs.config = lib.mkForce { };
  };
}

# deploy-rs node definitions, imported by flake.nix as the `deploy` output.
#
# Nodes are derived from the shared host table (./hosts.nix): every host with a
# non-null `ip` becomes a deploy target, addressed directly by LAN IP (you must
# be on the home network). Builds locally, copies the closure over SSH, and
# activates with magic rollback. Invoke with `deploy .#<host>`.
{
  self,
  inputs,
  hosts,
}:
let
  inherit (inputs.nixpkgs) lib;

  mkNode = name: h: {
    hostname = h.ip;
    profiles.system = {
      sshUser = "root";
      user = "root";
      path =
        inputs.deploy-rs.lib.${h.system or "x86_64-linux"}.activate.nixos
          self.nixosConfigurations.${name};
    };
  };
in
{
  nodes = builtins.mapAttrs mkNode (lib.filterAttrs (_: h: h.ip != null) hosts);
}

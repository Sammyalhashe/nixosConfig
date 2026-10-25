# Single source of truth for host metadata, consumed by flake.nix.
#
#   ip       - LAN IP for remote deploy-rs deployment; null = local-only
#              (desktops / WSL) and gets no deploy node.
#   hostname - the machine's real hostname, used by the switch/test guard
#              in nix/devshell.nix.
#   system   - build architecture (defaults to x86_64-linux when omitted).
#   comin    - false to opt out of comin auto-deploys (defaults to true for
#              hosts with an ip).
{
  homebase = {
    ip = "11.125.37.135";
    hostname = "homebase";
    # comin activates the default (KDE) generation, which tears the Ryoku
    # specialisation out from under a live session and crashes it.
    comin = false;
  };
  starship = {
    ip = null;
    hostname = "starship";
  };
  mothership = {
    ip = "11.125.37.101";
    hostname = "mothership";
  };
  oldboy = {
    ip = "11.125.37.175";
    hostname = "oldboy";
  };
  filestore = {
    ip = "11.125.37.98";
    hostname = "filestore";
    system = "aarch64-linux";
  };
  starshipwsl = {
    ip = null;
    hostname = "starship_wsl";
  };
  homebasewsl = {
    ip = null;
    hostname = "nixos";
  };
}

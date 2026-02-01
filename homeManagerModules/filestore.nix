{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./zellij.nix
    ./nushell.nix
    ./wsl.nix
    inputs.nix-openclaw.homeManagerModules.openclaw
  ];

  programs.openclaw = {
    enable = true;
    documents = ../.;
    instances.default = {
      enable = true;
    };
  };

  # Disable the document guard to allow overwriting existing files
  home.activation.openclawDocumentGuard = lib.mkForce (lib.hm.dag.entryBefore [ "writeBoundary" ] "");

  # Fix for openclawDirs attempting to use /bin/mkdir which doesn't exist on NixOS
  home.activation.openclawDirs = lib.mkForce (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run --quiet ${lib.getExe' pkgs.coreutils "mkdir"} -p /home/salhashemi2/.local/state/openclaw /home/salhashemi2/.openclaw/workspace /tmp/openclaw
    ''
  );

  # Disable openclawConfigFiles as it uses /bin/ln and seems redundant with home.file
  home.activation.openclawConfigFiles = lib.mkForce (lib.hm.dag.entryAfter [ "openclawDirs" ] "");

  programs.starship.enable = true;
  programs.git = {
    enable = true;
    settings = {
      user.name = "Sammy Al Hashemi";
      user.email = "sammy@salh.xyz";
    };
  };
  home.stateVersion = "23.11";
}

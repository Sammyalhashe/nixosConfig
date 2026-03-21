{
  pkgs,
  lib,
  config,
  ...
}:
let
  viture_virtual_display = pkgs.stdenv.mkDerivation {
    pname = "viture-virtual-display";
    version = "unstable-2024-03-01";

    src = pkgs.fetchFromGitHub {
      owner = "mgschwan";
      repo = "viture_virtual_display";
      rev = "main";
      sha256 = "sha256-4YtQ98M8S5i5i5i5i5i5i5i5i5i5i5i5i5i5i5i5i5="; # I'll need to get the real hash or use a flake input
    };
    # ...
  };
in
{
  # ...
}

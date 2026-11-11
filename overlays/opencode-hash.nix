# Drop once nixos-unstable includes NixOS/nixpkgs#582675.
final: prev: {
  opencode = prev.opencode.overrideAttrs (old: {
    node_modules = old.node_modules.overrideAttrs {
      outputHash =
        if final.stdenv.hostPlatform.isDarwin then
          "sha256-dIveiaiPFGSItwLyeMuPDxTE9gpvvnlTCB/+nG24qCc="
        else
          "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
    };
  });
}

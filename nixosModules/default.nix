{ username }
:
    {lib, inputs, pkgs, ...}@args:
    {
        imports = [
            ./desktop.nix
            ./syncthing.nix
            ./zsh.nix
            (import ./greetd.nix { inherit pkgs username inputs lib; })
        ];
    }


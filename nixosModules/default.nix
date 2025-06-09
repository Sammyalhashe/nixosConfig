{ username }
:
    {lib, inputs, pkgs, ...}@args:
    {
        imports = [
            ./desktop.nix
            ./zsh.nix
            (import ./greetd.nix { inherit pkgs username inputs lib; })
        ];
    }


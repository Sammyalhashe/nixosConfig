{ username }
:
    {lib, inputs, pkgs, ...}@args:
    {
        imports = [
            ./desktop.nix
            ./shell.nix
            (import ./greetd.nix { inherit pkgs username inputs lib; })
        ];
    }


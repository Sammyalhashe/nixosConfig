{ username, wsl ? false }
:
    {lib, inputs, pkgs, ...}@args:
    {
        imports = if wsl then [
            ./shell.nix
        ]
        else
        [
            ./desktop.nix
            ./shell.nix
            (import ./greetd.nix { inherit pkgs username inputs lib; })
        ];
    }


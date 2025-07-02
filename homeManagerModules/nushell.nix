{ config, pkgs, ... }:
let
sammy = "salhashemi2";
raspberrypi = "raspberrypi.local";
picloud = "picloud.local";
homebase = "homebase";
in
{
    programs.nushell = {
        enable = true;
        settings = {
            completions.external = {
                enable = true;
                max_results = 200;
            };
            buffer_editor = "nvim";
            edit_mode = "vi";
        };
        extraEnv = ''
            $env.EDITOR = "nvim"
            $env.config.shell_integration.osc133 = false
        '';
        shellAliases = {
            # common aliases
            nv = "nvim --remote-ui --server 127.0.0.1:8888";
            tm = "tmux";
            tm0 = "tmux a -t 0";
            tk0 = "tmux kill-session -t 0";
            yz = "yazi";
            z = "zellij";
            du = "dua";

            # nixos aliases
            hms = "home-manager switch";
            rb = "sudo nixos-rebuild switch";
            nix-shell = "nix-shell --command zsh";
            nsp = "nix-shell -p";
            nb = "nix build";
            nd = "nix develop";
            ns = "nix search nixpkgs";

            # git aliases
            grv = "git remote -v";
            gs = "git status";
            gf = "git fetch";
            grb = "git rebase";
            gb = "git branch";
            gco = "git checkout";
            gc = "git commit";
            gd = "git diff";
            gsa = "git stash";
            gsp = "git stash pop";

            # raspberry pi at home
            rpi = "ssh -Y ${sammy}@${raspberrypi}";
            picloud = "ssh -Y ${sammy}@${picloud}";
            hb = "ssh -Y ${sammy}@${homebase}";
        };
    };
}

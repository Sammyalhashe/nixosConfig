{ config, pkgs, ... }:
let sammy = "salhashemi2";
in
let ip = "192.168.1.99";
in
{
    programs.zsh = {
        enable = true;
        enableCompletion = true;
        shellAliases = {
            # common aliases
            nv = "nvim";
            tm = "tmux";
            tm0 = "tmux a -t 0";
            tk0 = "tmux kill-session -t 0";

            # nixos aliases
            hms = "home-manager switch";
            rb = "sudo nixos-rebuild switch";
            nix-shell = "nix-shell --command zsh";
            nsp = "nix-shell -p";
            nb = "nix build";
            nd = "nix develop";

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
            rpi = "ssh -Y ${sammy}@${ip}";
        };
        history = {
            size = 10000000;
            path = "${config.xdg.dataHome}/zsh/history";
        };

        zplug = {
            enable = true;
            plugins = [
                { name = "zsh-users/zsh-autosuggestions"; }
                { name = "zdharma-continuum/fast-syntax-highlighting"; }
                { name = "junegunn/fzf"; }
            ];
        };

        initExtra = ''
            bindkey -v
            bindkey '^R' history-incremental-search-backward

            if [ -n "$\{commands[fzf-share]\}" ]; then
              source "$(fzf-share)/key-bindings.zsh"
              source "$(fzf-share)/completion.zsh"
            fi
        '';

    };
}

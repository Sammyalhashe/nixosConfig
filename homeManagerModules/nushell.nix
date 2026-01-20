{
  pkgs,
  config,
  lib,
  ...
}:
let
  sammy = "salhashemi2";
  raspberrypi = "raspberrypi.local";
  picloud = "picloud.local";
  homebase = "homebase";
  wslCfg = config.environments.wsl;
in
{
  home.activation.syncSkateKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SKATE_BIN="${pkgs.nur.repos.charmbracelet.skate}/bin/skate"
    SECRET_FILE="/run/secrets/pop_resend_key"
    if [ -f "$SECRET_FILE" ]; then
      SECRET_VAL=$(cat "$SECRET_FILE")
      CURRENT_VAL=$($SKATE_BIN get pop-resend-key@api-keys 2>/dev/null || echo "")
      if [ "$SECRET_VAL" != "$CURRENT_VAL" ]; then
        run $SKATE_BIN set pop-resend-key@api-keys "$SECRET_VAL"
      fi
    fi
  '';

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
      $env.PERPLEXITY_API_KEY = (if ("/run/secrets/perplexity_api_key" | path exists) { open /run/secrets/perplexity_api_key | str trim } else { "" })
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
      pop = "with-env { RESEND_API_KEY: (skate get pop-resend-key@api-keys | str trim) } { ^pop }";
      pops = "with-env { RESEND_API_KEY: (skate get pop-resend-key@api-keys | str trim) } { ^pop --from sammy@salh.xyz}";

      # nushell specifics
      fg = "job unfreeze";

      # nixos aliases
      hms = "home-manager switch";
      rb = "sudo nixos-rebuild switch --flake .#";
      nix-shell = "nix-shell --command zsh";
      nsp = "nix-shell -p";
      nb = "nix build";
      nd = "nix develop";
      ns = "nix search nixpkgs";
      npkgs = "nix repl -f '<nixpkgs>'";
      ncg = "nix-collect-garbage -d";

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
      gp = "git push";
      gP = "git pull";

      # raspberry pi at home
      rpi = "ssh -Y ${sammy}@${raspberrypi}";
      picloud = "ssh -Y ${sammy}@${picloud}";
      hb = "ssh -Y ${sammy}@${homebase}";
    }
    // (lib.optionalAttrs wslCfg.enable {
      windows = "cd /mnt/c/Users/${wslCfg.windowsUsername}";
    });
    extraConfig = ''
      # grep history for pattern
      def hgrep [pattern?: string] {
        match $pattern {
            null => { history }
            _ => { history | where command =~ $pattern }
        }
      }

      # grep on ls
      def l [pattern?: string] {
        match $pattern {
            null => { ls }
            _ => { ls | where name =~ $pattern }
        }
      }

      # grep on file contents
      def f [file: string, pattern?: string] {
          open $file | where type == "file" | get name | each { |it| (open $it | where $it =~ $pattern) | if $it != [] { echo $it } }
      }

      # fzf search on job unfreeze and unfreeze the selected one
      def j [] {
        job unfreeze (
          job list
          | where type == "frozen"
          | each {|j| $"($j.id)\t($j.tag)\t($j.pids.0)" }
          | str join "\n"
          | fzf --height 40% --reverse --preview 'echo {} | split row '\t' | get 0 | split words | get 2 | into int | each { |x|  ^ps -fp $x }'
          | split row "\t"
          | get 0
          | into int
        )
      }

      # similar to the `j` command above, list all aliases in `fzf` and then set the prompt as the selected alias
      def a [] {
          let alias_name = (
          help aliases
          | each {|a| $"($a.name)\t($a.expansion)\t($a.description)" }
          | str join "\n"
          | fzf --height 40% --reverse --preview 'echo {} | split row "\t" | get 1'
          | split row "\t"
          | get 0
          );
          if $alias_name != "" {
          echo "Setting prompt to alias: $alias_name";
          prompt $alias_name;
          } else {
          echo "No alias selected.";
          }
      }

      # given a url to a tarball, download and extract it to a folder named after the tarball
      def untar [url: string] {
          let filename = ($url | split row "/" | last);
          let foldername = ($filename | str replace ".tar.gz" "" | str replace ".tgz" "" | str replace ".tar" "");
          ^mkdir $foldername;
          ^curl -L $url -o $filename;
          ^tar -xf $filename -C $foldername;
          ^rm $filename;
          echo "Extracted to $foldername"
      }

      source ${pkgs.nu_scripts}/share/nu_scripts/custom-completions/git/git-completions.nu
    '';
  };
}

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
  wslCfg = lib.attrByPath [ "environments" "wsl" ] { enable = false; } config;
in
{
  home.activation.syncSkateKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SKATE_BIN="${pkgs.nur.repos.charmbracelet.skate}/bin/skate"

    sync_key() {
      local secret_name="$1"
      local skate_name="$2"
      local secret_file="/run/secrets/$secret_name"
      if [ -f "$secret_file" ] && [ -r "$secret_file" ]; then
        SECRET_VAL=$(cat "$secret_file")
        CURRENT_VAL=$($SKATE_BIN get "$skate_name@api-keys" 2>/dev/null || echo "")
        if [ "$SECRET_VAL" != "$CURRENT_VAL" ]; then
          run $SKATE_BIN set "$skate_name@api-keys" "$SECRET_VAL"
        fi
      fi
    }

    sync_key "pop_resend_key" "pop-resend-key"
    sync_key "perplexity_api_key" "perplexity-api-key"
    sync_key "gemini_api_key" "gemini-api-key"
    sync_key "brave_api_key" "brave-api-key"
    sync_key "openrouter_api_key" "openrouter-api-key"
    sync_key "chainstack_api_key" "chainstack-api-key"
    sync_key "nvidia_api_key" "nvidia-api-key"
    sync_key "telegram_bot_token" "telegram-bot-token"
    sync_key "cloudflare_token" "cloudflare-token"
    sync_key "polyclaw_private_key" "polyclaw-private-key"
    sync_key "eth_rpc_url" "eth-rpc-url"
    sync_key "eth_private_key" "eth-private-key"
    sync_key "coinbase_api_key_clawdbot" "coinbase-api-key-clawdbot"
    sync_key "coinbase_api_id_clawdbot" "coinbase-api-id-clawdbot"
    sync_key "coinbase_api_secret_clawdbot" "coinbase-api-secret-clawdbot"
    sync_key "coinbase_api_id_coinbase_trader" "coinbase-api-id-coinbase-trader"
    sync_key "coinbase_api_secret_coinbase_trader" "coinbase-api-secret-coinbase-trader"
    sync_key "icloud_email" "icloud-email"
    sync_key "icloud_password" "icloud-password"
    sync_key "openclaw_icloud_user" "openclaw-icloud-user"
    sync_key "filestore_user_password" "filestore-user-password"
    sync_key "filestore_wifi_ssid" "filestore-wifi-ssid"
    sync_key "filestore_wifi_password" "filestore-wifi-password"
    sync_key "filestore_authentik_secret" "filestore-authentik-secret"
    sync_key "filestore_postgres_password" "filestore-postgres-password"
    sync_key "vaultwarden_sso_client_secret" "vaultwarden-sso-client-secret"
    sync_key "vaultwarden_admin_token" "vaultwarden-admin-token"
    sync_key "nextcloud_admin_password" "nextcloud-admin-password"
    sync_key "syncthing_gui_password" "syncthing-gui-password"
    sync_key "cachix_token" "cachix-token"
    sync_key "supernote_email" "supernote-email"
    sync_key "supernote_password" "supernote-password"
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
      $env.PATH = ($env.PATH | prepend "${pkgs.zoxide}/bin")
      $env.EDITOR = "nvim"
      $env.config.shell_integration.osc133 = false
      $env.PERPLEXITY_API_KEY = (if ("/run/secrets/perplexity_api_key" | path exists) { open /run/secrets/perplexity_api_key | str trim } else { "" })
      $env.ANTHROPIC_BASE_URL = "http://11.125.37.101:4000"
      $env.ANTHROPIC_API_KEY = "sk-no-key-required"
      $env.OPENROUTER_API_KEY = (if ("/run/secrets/openrouter_api_key" | path exists) { open /run/secrets/openrouter_api_key | str trim } else { "" })
      $env.GEMINI_API_KEY = (if ("/run/secrets/gemini_api_key" | path exists) { open /run/secrets/gemini_api_key | str trim } else { "" })
    '';
    shellAliases = {
      # common aliases
      nv = "nvim --remote-ui --server 127.0.0.1:8888";
      tm = "tmux";
      tm0 = "tmux a -t 0";
      tk0 = "tmux kill-session -t 0";
      yz = "yazi";
      zj = "zellij";
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
      cleanup = "sudo nix-collect-garbage -d";

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


      def login-enterprise-wifi [ssid: string, username: string, password: string] {
        nmcli con add type wifi ifname wlo1 con-name $ssid ssid $ssid -- wifi-sec.key-mgmt wpa-eap 802-1x.eap peap 802-1x.phase2-auth mschapv2 802-1x.identity $username 802-1x.password $password
      }

      source ${pkgs.nu_scripts}/share/nu_scripts/custom-completions/git/git-completions.nu
    '';
  };
}

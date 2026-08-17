{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  # Home directories on oldboy that the unprivileged `hermes` service user is
  # granted read+write access to (via POSIX ACLs + ReadWritePaths below).
  sharedDirs = [
    "/home/salhashemi2/nixosConfig"
    "/home/salhashemi2/projects"
  ];
in
{

  # 1. Tell sops-nix to decrypt your existing openrouter secret
  sops.secrets.openrouter_api_key = {
    # Automatically restarts the agent if you rotate the key in sops
    restartUnits = [ "hermes-agent.service" ];
  };

  sops.secrets.CLINE_HERMES_API_KEY = {
    restartUnits = [ "hermes-agent.service" ];
  };

  sops.secrets.telegram_bot_token = {
    # Automatically restarts the agent if you rotate the key in sops
    restartUnits = [ "hermes-agent.service" ];
  };

  sops.secrets.brave_api_key = {
    # Automatically restarts the agent if you rotate the key in sops
    restartUnits = [ "hermes-agent.service" ];
  };

  # HA-MCP exposes its MCP endpoint as a secret webhook URL — the URL *is* the
  # credential, so it must not land in the world-readable Nix store via
  # `settings` below.
  sops.secrets.ha_mcp_webhook_url = {
    # Automatically restarts the agent if you rotate the key in sops
    restartUnits = [ "hermes-agent.service" ];
  };

  # Coinbase CDP credentials for hermes
  sops.templates."hermes-coinbase-key" = {
    content = ''
      {
        "name": "${config.sops.placeholder.cb_hardware_maker_org_name}",
        "privateKey": "${config.sops.placeholder.cb_hardware_maker_key}"
      }
    '';
    owner = "hermes";
    path = "/var/lib/hermes/coinbase_api_key.json";
    restartUnits = [ "hermes-agent.service" ];
  };

  # 2. Use a sops template to dynamically generate a systemd-compatible env file
  sops.templates."hermes-agent-secrets.env".content = ''
    OPENROUTER_API_KEY="${config.sops.placeholder.openrouter_api_key}"
    TELEGRAM_BOT_TOKEN="${config.sops.placeholder.telegram_bot_token}"
    # You can append other API keys here later (e.g., Alpaca, E-Trade, Finnhub)
    TELEGRAM_ALLOWED_USERS="8555669756"
    HERMES_MAX_TOKENS=8192
    BRAVE_SEARCH_API_KEY="${config.sops.placeholder.brave_api_key}"
    CLINEPASS_API_KEY="${config.sops.placeholder.CLINE_HERMES_API_KEY}"
    COMPOSIO_API_KEY="${config.sops.placeholder.composio_api_key}"
    HA_MCP_URL="${config.sops.placeholder.ha_mcp_webhook_url}"
    GATEWAY_ALLOW_ALL_USERS=true
    FASTMAIL_API_KEY="${config.sops.placeholder.fastmail_hermes_api_key}"
  '';

  # 3. Configure the Hermes Agent Service
  services.hermes-agent = {
    enable = true;

    package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;

    environmentFiles = [
      config.sops.templates."hermes-agent-secrets.env".path
    ];

    extraDependencyGroups = [ "messaging" ];

    settings = {
      # Active provider + model. `provider`/`model` are plain strings, matching
      # the shape used in fallback_providers / auxiliary below.
      provider = "custom:clinepass";
      model = "cline-pass/qwen3.7-max";

      mcp_servers = {
        composio = {
          url = "https://connect.composio.dev/mcp";
          headers = {
            "x-consumer-api-key" = "\${COMPOSIO_API_KEY}";
          };
          connect_timeout = 60;
          timeout = 180;
        };
        robinhood-trading = {
          url = "https://agent.robinhood.com/mcp/trading";
          auth = "oauth"; # Automatically coordinates PKCE dynamic registration & background token refreshes
        };
        home-assistant = {
          # HA-MCP custom component (homeassistant-ai/ha-mcp), not HA's built-in
          # /api/mcp — the custom one also covers automations, dashboards,
          # traces and logs. Secret webhook URL comes from the env file.
          url = "\${HA_MCP_URL}";
          connect_timeout = 30;
          timeout = 180;
        };
        fastmail = {
          url = "https://api.fastmail.com/mcp";
          headers = {
            # Note the literal "Bearer " string before the variable interpolation
            Authorization = "Bearer \${FASTMAIL_API_KEY}";
          };
        };
      };

      web = {
        backend = "brave-free";
      };

      fallback_providers = [
        {
          provider = "openrouter";
          model = "deepseek/deepseek-r1";
        }
        {
          # If OpenRouter is totally down, try to use the local Strix Halo machine
          provider = "custom:mothership";
          model = "qwen3.6";
        }
      ];

      custom_providers = [
        {
          name = "clinepass";
          base_url = "https://api.cline.bot/api/v1";
          key_env = "CLINEPASS_API_KEY"; # Tells Hermes to pull CLINEPASS_API_KEY from .env
          models = [
            "cline-pass/qwen3.7-max"
            "cline-pass/deepseek-v4-pro"
            "cline-pass/glm-5.2"
          ];
        }
        {
          name = "mothership";
          base_url = "http://mothership.salh.xyz:4000/v1";
          api_key = "none";
          models = [
            "qwen-3.6"
            "qwen-flash"
          ];
        }
      ];

      auxiliary = {
        compression = {
          provider = "custom:mothership";
          model = "qwen-flash";
        };
        web_extract = {
          provider = "custom:mothership";
          model = "qwen-flash";
        };
        title_generation = {
          provider = "custom:mothership";
          model = "qwen-flash";
        };
      };

      terminal = {
        backend = "local";
        # Canonical working-directory setting (replaces the deprecated
        # MESSAGING_CWD env var, which the module still sets and we unset below).
        cwd = config.services.hermes-agent.workingDirectory;
      };

      gateway = {
        platforms = {
          telegram = {
            enabled = true;
          };
        };
      };
    };

    extraPackages = with pkgs; [
      python3
      python3Packages.pip
      nodejs
      jq
    ];
  };

  # 4. Inject the generated environment file into the Hermes systemd service
  systemd.services.hermes-agent = {

    preStart = ''
      mkdir -p /var/lib/hermes/.hermes
      cp -f ${
        (pkgs.formats.yaml { }).generate "hermes-config.yaml" config.services.hermes-agent.settings
      } /var/lib/hermes/.hermes/config.yaml
      chmod 600 /var/lib/hermes/.hermes/config.yaml

      # Set up Coinbase CLI default environment from the hardware maker key
      if [ ! -f /var/lib/hermes/.config/coinbase/config.json ]; then
        ${pkgs.nodejs}/bin/npx -y @coinbase/coinbase-cli env hermes \
          --key-file /var/lib/hermes/coinbase_api_key.json \
          --url https://api.coinbase.com \
          --allow-plaintext-secrets || true
      fi
    '';

    environment.PYTHONPATH = "${pkgs.python3Packages.python-telegram-bot}/${pkgs.python3.sitePackages}";

    # The hermes-agent module still sets the deprecated MESSAGING_CWD env var;
    # unset it (the value now lives in settings.terminal.cwd → config.yaml).
    environment.MESSAGING_CWD = lib.mkForce null;

    serviceConfig = {
      EnvironmentFile = [ config.sops.templates."hermes-agent-secrets.env".path ];
      TimeoutStopSec = "240s";
      # The hermes-agent module sets ProtectSystem=strict, which makes the whole
      # filesystem read-only except a few paths — so POSIX ACLs alone won't allow
      # writes. These entries merge with the module's ReadWritePaths
      # (/var/lib/hermes*) to permit writes into the shared home directories.
      ReadWritePaths = sharedDirs;
    };

  };

  # 5. Grant the unprivileged hermes user read+write on the shared home dirs.
  #    ProtectHome=false (module default) already lets the service see /home;
  #    these ACLs open up exactly the chosen subdirs — plus traverse-only on the
  #    home root — without exposing the rest of the home directory. The recursive
  #    `A+` lines stamp existing files and add default ACLs so new files inherit
  #    access for both hermes and salhashemi2 (hermes writes as hermes:hermes
  #    under UMask=0007, which would otherwise lock you out of files it creates).
  systemd.tmpfiles.rules = [
    # Enforce 0711 mode so the ACL mask permits directory traversal
    "z /home/salhashemi2 0711 salhashemi2 users - -"
    # Ensure the shared projects dir exists (nixosConfig already does).
    "d /home/salhashemi2/projects 0755 salhashemi2 users - -"
    # Traverse-only into the home root: descend to the shared subdirs without
    # being able to list or read anything else in the home directory.
    "a+ /home/salhashemi2 - - - - u:hermes:x"
  ]
  ++ map (dir: "A+ ${dir} - - - - u:hermes:rwX,d:u:hermes:rwX,d:u:salhashemi2:rwX") sharedDirs;
}

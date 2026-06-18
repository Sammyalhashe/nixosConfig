{
  config,
  pkgs,
  inputs,
  ...
}:
{

  # 1. Tell sops-nix to decrypt your existing openrouter secret
  sops.secrets.openrouter_api_key = {
    # Automatically restarts the agent if you rotate the key in sops
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

  # 2. Use a sops template to dynamically generate a systemd-compatible env file
  sops.templates."hermes-agent-secrets.env".content = ''
    OPENROUTER_API_KEY="${config.sops.placeholder.openrouter_api_key}"
    TELEGRAM_BOT_TOKEN="${config.sops.placeholder.telegram_bot_token}"
    # You can append other API keys here later (e.g., Alpaca, E-Trade, Finnhub)
    TELEGRAM_ALLOWED_USERS="8555669756"
    HERMES_MAX_TOKENS=8192
    BRAVE_SEARCH_API_KEY="${config.sops.placeholder.brave_api_key}"
  '';

  # 3. Configure the Hermes Agent Service
  services.hermes-agent = {
    enable = true;

    package = inputs.hermes-agent.packages.${pkgs.system}.default;

    environmentFiles = [
      config.sops.templates."hermes-agent-secrets.env".path
    ];

    extraDependencyGroups = [ "messaging" ];

    settings = {
      model = {
        default = "~anthropic/claude-sonnet-latest";
      };

      mcp_servers = {
        robinhood-trading = {
          url = "https://agent.robinhood.com/mcp/trading";
          auth = "oauth"; # Automatically coordinates PKCE dynamic registration & background token refreshes
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
          provider = "custom:mothership-server";
          model = "qwen3.6";
        }
      ];

      custom_providers = [
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
          provider = "custom:mothership-server";
          model = "qwen-flash";
        };
        web_extract = {
          provider = "custom:mothership-server";
          model = "qwen-flash";
        };
        title_generation = {
          provider = "custom:mothership-server";
          model = "qwen-flash";
        };
      };

      terminal = {
        backend = "local";
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

    environment.PYTHONPATH = "${pkgs.python3Packages.python-telegram-bot}/${pkgs.python3.sitePackages}";

    serviceConfig = {
      EnvironmentFile = [ config.sops.templates."hermes-agent-secrets.env".path ];
      TimeoutStopSec = "240s";
    };

  };
}

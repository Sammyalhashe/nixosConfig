{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  polyclaw-wrapper = pkgs.writeShellScriptBin "polyclaw" ''
    export PATH="${pkgs.uv}/bin:$PATH"
    if [ ! -d "$HOME/.picoclaw/workspace/skills/polyclaw" ]; then
      echo "Error: PolyClaw skill directory not found at $HOME/.picoclaw/workspace/skills/polyclaw"
      exit 1
    fi
    cd $HOME/.picoclaw/workspace/skills/polyclaw
    # Pass environment variables from the environment if set
    exec uv run python scripts/polyclaw.py "$@"
  '';

  better-memory-wrapper = pkgs.writeShellScriptBin "better-memory" ''
    export PATH="${pkgs.nodejs_25}/bin:$PATH"
    if [ ! -d "$HOME/.picoclaw/workspace/skills/better-memory" ]; then
      echo "Error: Better Memory skill directory not found at $HOME/.picoclaw/workspace/skills/better-memory"
      exit 1
    fi
    cd $HOME/.picoclaw/workspace/skills/better-memory
    exec node scripts/cli.js "$@"
  '';
in
{
  imports = [
    inputs.nix-picoclaw.homeManagerModules.picoclaw
  ];

  home.packages = with pkgs; [
    polyclaw-wrapper
    better-memory-wrapper
  ];

  programs.picoclaw = {
    enable = true;
    environmentFile = "/run/secrets/rendered/picoclaw-env";
    settings = {
      tools = {
        allow = [
          "browser"
          "read"
          "write"
          "exec"
        ];
      };
      agents = {
        defaults = {
          skipBootstrap = true;
          timeoutSeconds = 300;
          models = {
            "mothership-reasoning/gpt-oss-120b" = {
              alias = "gpt-oss:120b";
            };
            "google/gemini-3.0-pro-preview" = {
              alias = "gemini-3";
            };
            "nvidia/moonshotai/kimi-k2.5" = {
              alias = "kimi-k2";
            };
          };
          model = {
            primary = "nvidia/moonshotai/kimi-k2.5";
            fallbacks = [
              "mothership-reasoning/gpt-oss-120b"
              "mothership-local/qwen2.5-coder-32b-instruct"
              "openrouter/arcee-ai/trinity-large-preview:free"
              "lemonade/user.Qwen-32B-Coder"
              "ollama/qwen2.5:7b"
              "ollama/qwen2.5-coder:7b"
              "ollama/llama3.1:8b"
              "ollama/MFDoom/deepseek-r1-tool-calling:8b"
            ];
          };
        };
      };
      gateway = {
        mode = "local";
        auth = {
          token = "temporary-token-123456";
        };
      };
      tools = {
        web = {
          search = {
            apiKey = "env:BRAVE_API_KEY";
          };
        };
      };
      commands = {
        restart = true;
      };
      channels = {
        telegram = {
          enabled = true;
          tokenFile = "/run/secrets/telegram_bot_token";
          allowFrom = [
            8555669756
          ];
          groups = {
            "*" = {
              requireMention = true;
            };
            "-1001234567890" = {
              requireMention = false;
            };
            "-1002345678901" = {
              requireMention = true;
            };
          };
        };
      };
      plugins = {
        entries = {
          whatsapp = {
            enabled = false;
          };
          telegram = {
            enabled = true;
          };
        };
      };
      models = {
        providers = {
          mothership-local = {
            api = "openai-completions";
            baseUrl = "http://11.125.37.101:8012/v1";
            apiKey = "none";
            models = [
              {
                id = "qwen2.5-coder-32b-instruct";
                name = "Qwen 2.5 Coder 32B (Mothership)";
              }
            ];
          };
          mothership-reasoning = {
            api = "openai-completions";
            baseUrl = "http://11.125.37.101:8013/v1";
            apiKey = "none";
            models = [
              {
                id = "gpt-oss-120b";
                name = "GPT-OSS-120B (Mothership Reasoning)";
                reasoning = true;
              }
            ];
          };
          openrouter = {
            api = "openai-completions";
            baseUrl = "https://openrouter.ai/api/v1";
            apiKey = "env:OPENROUTER_API_KEY";
            models = [
              {
                id = "arcee-ai/trinity-large-preview:free";
                name = "Trinity Large Preview (Free)";
              }
            ];
          };
          nvidia = {
            api = "openai-completions";
            baseUrl = "https://integrate.api.nvidia.com/v1";
            apiKey = "env:NVIDIA_API_KEY";
            models = [
              {
                id = "moonshotai/kimi-k2.5";
                name = "Kimi k2.5 (NVIDIA)";
                reasoning = true;
              }
            ];
          };
          google = {
            api = "google-generative-ai";
            baseUrl = "https://generativelanguage.googleapis.com/v1beta";
            apiKey = "env:GEMINI_API_KEY";
            models = [
              {
                id = "gemini-2.5-pro";
                name = "Gemini 2.5 Pro";
              }
              {
                id = "gemini-3.0-pro-preview";
                name = "Gemini 3.0 Pro (Preview)";
              }
            ];
          };
          lemonade = {
            api = "openai-completions";
            baseUrl = "http://11.125.37.172:8001/v1";
            apiKey = "any";
            models = [
              {
                id = "user.Qwen-32B-Coder";
                name = "Qwen 2.5 Coder 32B (Lemonade)";
              }
            ];
          };
          ollama = {
            api = "openai-responses";
            baseUrl = "http://11.125.37.135:11434/v1";
            apiKey = "ollama";
            models = [
              {
                id = "MFDoom/deepseek-r1-tool-calling:8b";
                name = "DeepSeek R1 Tools (Doom)";
                reasoning = true;
              }
              {
                id = "qwen2.5:7b";
                name = "Qwen 2.5 7B";
              }
              {
                id = "deepseek-r1:7b";
                name = "DeepSeek R1 7B";
                reasoning = true;
              }
              {
                id = "qwen2.5-coder:7b";
                name = "Qwen 2.5 Coder 7B";
              }
              {
                id = "llama3.1:8b";
                name = "Llama 3.1 8B";
              }
            ];
          };
        };
      };
    };
  };

  home.activation.installPicoClawSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p $HOME/.picoclaw/workspace/skills

    install_skill() {
      name=$1
      src=$2
      target="$HOME/.picoclaw/workspace/skills/$name"
      
      # Sync source to target, making files writable and excluding build artifacts
      ${pkgs.rsync}/bin/rsync -avz --chmod=u+w --exclude 'node_modules' --exclude '.venv' --exclude 'package-lock.json' --exclude 'uv.lock' "$src/" "$target/"
    }

    install_skill "coding-agent" "${inputs.plugin-coding}"
    install_skill "git-essentials" "${inputs.plugin-git}"
    install_skill "docker-essentials" "${inputs.plugin-docker}"
    install_skill "system-monitor" "${inputs.plugin-system}"
    install_skill "filesystem" "${inputs.plugin-filesystem}"
    install_skill "process-watch" "${inputs.plugin-process}"
    install_skill "polyclaw" "${inputs.plugin-polyclaw}"
    install_skill "better-memory" "${inputs.plugin-better-memory}"
  '';

  systemd.user.services.picoclaw-gateway.Service = {
    Environment = lib.mkForce [
      "HOME=/home/salhashemi2"
      "SHELL=${pkgs.bash}/bin/bash"
      "PICOCLAW_STATE_DIR=/home/salhashemi2/.picoclaw"
      "PICOCLAW_NIX_MODE=1"
      "PICOCLAW_QUIET=1"
      "PATH=${
        lib.makeBinPath [
          pkgs.python3
          pkgs.nix
          pkgs.podman
          pkgs.coreutils
          pkgs.bash
        ]
      }:/run/current-system/sw/bin:/etc/profiles/per-user/salhashemi2/bin"
      "PICOCLAW_CONFIG_PATH=/home/salhashemi2/.config/picoclaw/config.json"
    ];
    StandardOutput = lib.mkForce "journal";
    StandardError = lib.mkForce "journal";
  };
}
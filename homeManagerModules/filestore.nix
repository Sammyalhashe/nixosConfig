{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  polyclaw-wrapper = pkgs.writeShellScriptBin "polyclaw" ''
    export PATH="${pkgs.uv}/bin:$PATH"
    if [ ! -d "$HOME/.openclaw/workspace/skills/polyclaw" ]; then
      echo "Error: PolyClaw skill directory not found at $HOME/.openclaw/workspace/skills/polyclaw"
      exit 1
    fi
    cd $HOME/.openclaw/workspace/skills/polyclaw
    # Pass environment variables from the environment if set
    exec uv run python scripts/polyclaw.py "$@"
  '';

  better-memory-wrapper = pkgs.writeShellScriptBin "better-memory" ''
    export PATH="${pkgs.nodejs_25}/bin:$PATH"
    if [ ! -d "$HOME/.openclaw/workspace/skills/better-memory" ]; then
      echo "Error: Better Memory skill directory not found at $HOME/.openclaw/workspace/skills/better-memory"
      exit 1
    fi
    cd $HOME/.openclaw/workspace/skills/better-memory
    exec node scripts/cli.js "$@"
  '';
in
{
  imports = [
    ./zellij.nix
    ./nushell.nix
    ./wsl.nix
    inputs.nix-openclaw.homeManagerModules.openclaw
  ];

  home.packages = with pkgs; [
    btop
    podman
    ripgrep
    fzf
    jq
    python3
    rsync
    polyclaw-wrapper
    better-memory-wrapper
  ];

  programs.openclaw = {
    enable = true;
    firstParty = {
      summarize.enable = true; # Summarize web pages, PDFs, videos
      peekaboo.enable = false; # Take screenshots
      poltergeist.enable = false; # Control your macOS UI
      sag.enable = false; # Text-to-speech
      camsnap.enable = false; # Camera snapshots
      gogcli.enable = false; # Google Calendar
      bird.enable = false; # Twitter/X
      sonoscli.enable = false; # Sonos control
      imsg.enable = false; # iMessage
    };
    skills = [ ];
    documents = ../openclaw;
    instances.default = {
      enable = true;
      config = {
        agents.defaults = {
          skipBootstrap = true;
          model = {
            primary = "google/gemini-2.5-pro";
            fallbacks = [
              "openrouter/arcee-ai/trinity-large-preview:free"
              "lemonade/user.Qwen-32B-Coder"
              "ollama/qwen2.5:7b"
              "google/gemini-3-pro-preview"
              "ollama/qwen2.5-coder:7b"
              "ollama/llama3.1:8b"
              "ollama/MFDoom/deepseek-r1-tool-calling:8b"
            ];
          };
        };
        gateway = {
          mode = lib.mkForce "local";
          auth.token = "temporary-token-123456";
        };
        commands = {
          restart = true;
        };
        channels.telegram = {
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
            }; # couples group
            "-1002345678901" = {
              requireMention = true;
            }; # noisy group
          };
        };
        plugins.entries.whatsapp.enabled = false;
        models = {
          providers = {
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
            lemonade = {
              api = "openai-completions";
              baseUrl = "http://11.125.37.172:8001/v1";
              apiKey = "any"; # Often ignored for local servers, but required by schema
              models = [
                {
                  id = "user.Qwen-32B-Coder";
                  name = "Qwen 2.5 Coder 32B (Lemonade)";
                }
              ];
            };
            google = {
              api = "google-generative-ai";
              apiKey = "env:GEMINI_API_KEY";
              baseUrl = "https://generativelanguage.googleapis.com/v1beta";
              auth = "api-key";
              models = [
                {
                  id = "gemini-3-pro-preview";
                  name = "Gemini 3.0 Pro (Preview)";
                }
                {
                  id = "gemini-2.5-pro";
                  name = "Gemini 2.5 Pro";
                }
              ];
            };
            ollama = {
              api = "openai-responses";
              baseUrl = "http://11.125.37.135:11434/v1";
              # Required but ignored by Ollama
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
  };

  # Activation script to install skills mutably so we can run npm install/uv sync inside them
  home.activation.installOpenClawSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p $HOME/.openclaw/workspace/skills

    install_skill() {
      name=$1
      src=$2
      target="$HOME/.openclaw/workspace/skills/$name"
      
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

  # Disable the document guard to allow overwriting existing files
  home.activation.openclawDocumentGuard = lib.mkForce (lib.hm.dag.entryBefore [ "writeBoundary" ] "");

  # Inject system and user profile paths into the OpenClaw gateway service
  systemd.user.services.openclaw-gateway.Service = {
    Environment = lib.mkForce [
      "HOME=/home/salhashemi2"
      "SHELL=${pkgs.bash}/bin/bash"
      "OPENCLAW_CONFIG_PATH=/home/salhashemi2/.openclaw/openclaw.json"
      "OPENCLAW_STATE_DIR=/home/salhashemi2/.openclaw"
      "OPENCLAW_NIX_MODE=1"
      "PATH=${
        lib.makeBinPath [
          pkgs.python3
          pkgs.nix
          pkgs.podman
          pkgs.coreutils
          pkgs.bash
        ]
      }:/run/current-system/sw/bin:/etc/profiles/per-user/salhashemi2/bin"
    ];
    EnvironmentFile = "/run/secrets/rendered/openclaw-env";
  };
  programs.starship.enable = true;
  programs.git = {
    enable = true;
    settings = {
      user.name = "Sammy Al Hashemi";
      user.email = "sammy@salh.xyz";
    };
  };
  home.stateVersion = "23.11";
}

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
    inputs.nix-openclaw.homeManagerModules.openclaw
  ];

  home.packages = with pkgs; [
    polyclaw-wrapper
    better-memory-wrapper
  ];

  home.file.".openclaw/workspace/skills/aider-bootstrap/SKILL.md".text = ''
---
name: aider-bootstrap
description: Bootstrap new software projects using Aider. Automatically handles directory creation and git initialization required by Aider.
---

# Aider Project Bootstrapper

Use this skill when the user wants to create, scaffold, or bootstrap a new project using Aider.

## Workflow

1.  **Create Directory**: Ensure the target directory exists.
    ```bash
    mkdir -p <target_directory>
    ```

2.  **Safety Check**: Verify the target directory is NOT the root filesystem.
    *   Target must NOT be `/`.
    *   Target must NOT be `/home/username` (unless explicitly requested, but prefer subdirs).

3.  **Git Initialization**: Aider requires a git repository to function.
    *   Check if git is initialized: `cd <target_directory> && git status`
    *   If not, initialize it: `cd <target_directory> && git init`

4.  **Run Aider**: Invoke aider with the prompt.
    ```bash
    cd <target_directory> && aider --no-auto-commits --message "<prompt>"
    ```

## Example

**User:** "Make a python calculator in `py-calc`"

**Agent Action:**
1.  `mkdir -p py-calc`
2.  `cd py-calc && git init`
3.  `cd py-calc && aider --message "Build a python calculator..."`
  '';

  programs.openclaw = {
    enable = true;
    bundledPlugins = {
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
        tools = {
          allow = [
            "browser"
            "read"
            "write"
            "exec"
          ];
        };
        agents.defaults = {
          skipBootstrap = true;
          timeoutSeconds = 300; # 5 minutes to prevent timeouts
          maxConcurrent = 8;
          subagents = {
            maxConcurrent = 16;
          };
          models = {
            "mothership-proxy/gpt-oss-120b" = {
              alias = "master";
            };
            "google/gemini-3.1-pro-preview" = {
              alias = "gemini-3.1";
            };
            "google/gemini-3-flash" = {
              alias = "gemini-3-flash";
            };
          };
          model = {
            primary = "mothership-proxy/gpt-oss-120b";
            fallbacks = [
              "google/gemini-3.1-pro-preview"
              "google/gemini-3-flash"
            ];
          };
        };
        gateway = {
          mode = lib.mkForce "local";
          auth.token = "temporary-token-123456";
        };
        tools.web.search.apiKey = "env:BRAVE_API_KEY";
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
        plugins.entries.telegram.enabled = true;
                                models = {
                  providers = {
                                                                mothership-proxy = {
                                                                  api = "openai-completions";
                                                                  baseUrl = "http://11.125.37.101:4000/v1";
                                                                  apiKey = "any";
                                                                  models = [                                        {                                  id = "gpt-oss-120b";
                                  name = "GPT-OSS 120B (via Mothership)";
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
                                  id = "gemini-3.1-pro-preview";
                                  name = "Gemini 3.1 Pro (Preview)";
                                  reasoning = true;
                                }
                                {
                                  id = "gemini-3-flash";
                                  name = "Gemini 3 Flash";
                                }
                                {
                                  id = "gemini-2.5-pro";
                                  name = "Gemini 2.5 Pro";
                                }
                                {
                                  id = "gemini-2.5-flash";
                                  name = "Gemini 2.5 Flash";
                                }
                                {
                                  id = "gemini-2.0-flash";
                                  name = "Gemini 2.0 Flash";
                                }
                              ];
                            };            lemonade = {
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

    # Install dependencies for better-memory
    if [ -f "$HOME/.openclaw/workspace/skills/better-memory/package.json" ]; then
      cd "$HOME/.openclaw/workspace/skills/better-memory"
      # Ensure node is in path for npm
      export PATH="${pkgs.nodejs_25}/bin:$PATH"
      ${pkgs.nodejs_25}/bin/npm install --silent
    fi
  '';

  home.activation.openclawDocumentGuard = lib.mkForce (lib.hm.dag.entryBefore [ "writeBoundary" ] "");

  systemd.user.services.openclaw-gateway.Service = {
    Environment = lib.mkForce [
      "HOME=/home/salhashemi2"
      "SHELL=${pkgs.bash}/bin/bash"
      "OPENCLAW_CONFIG_PATH=/home/salhashemi2/.openclaw/openclaw.json"
      "OPENCLAW_STATE_DIR=/home/salhashemi2/.openclaw"
      "OPENCLAW_NIX_MODE=1"
      "OPENCLAW_QUIET=1"
      "PATH=${
        lib.makeBinPath [
          pkgs.python3
          pkgs.nix
          pkgs.podman
          pkgs.coreutils
          pkgs.bash
          pkgs.uv
          pkgs.nodejs
          pkgs.git
          pkgs.rsync
          pkgs.sqlite
        ]
      }:/run/current-system/sw/bin:/etc/profiles/per-user/salhashemi2/bin"
    ];
    EnvironmentFile = "/run/secrets/rendered/openclaw-env";
    StandardOutput = lib.mkForce "journal";
    StandardError = lib.mkForce "journal";
  };
}
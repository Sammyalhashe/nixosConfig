{
  inputs,
  lib,
  pkgs,
  ...
}:
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
    # NOTE: This is the 'proper' declarative way to add skills.
    # It is currently commented out because it often collides with existing directories
    # or fails to create them during first-time activation. We use manual home.file
    # links (at the bottom of this file) to guarantee reliability on this server.
    #
    # skills = [
    #   { name = "coding-agent"; mode = "copy"; source = inputs.plugin-coding; }
    #   { name = "git-essentials"; mode = "copy"; source = inputs.plugin-git; }
    #   { name = "docker-essentials"; mode = "copy"; source = inputs.plugin-docker; }
    #   { name = "system-monitor"; mode = "copy"; source = inputs.plugin-system; }
    #   { name = "filesystem"; mode = "copy"; source = inputs.plugin-filesystem; }
    #   { name = "process-watch"; mode = "copy"; source = inputs.plugin-process; }
    # ];
    skills = [ ];
    documents = ../openclaw;
    instances.default = {
      enable = true;
      config = {
        agents.defaults = {
          skipBootstrap = true;
          model = {
            primary = "ollama/deepseek-r1:7b";
            fallbacks = [
              "google/gemini-3-pro-preview"
              "google/gemini-2.5-pro"
              "ollama/qwen2.5-coder:7b"
              "ollama/llama3.1:8b"
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
            google = {
              api = "google-generative-ai";
              apiKey = "***REMOVED***";
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
                  id = "deepseek-r1:7b";
                  name = "DeepSeek R1 7B";
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

  # Manually link skills since the module's declarative skills feature is not working as expected
  home.file = {
    ".openclaw/workspace/skills/coding-agent" = {
      source = inputs.plugin-coding;
      recursive = true;
    };
    ".openclaw/workspace/skills/git-essentials" = {
      source = inputs.plugin-git;
      recursive = true;
    };
    ".openclaw/workspace/skills/docker-essentials" = {
      source = inputs.plugin-docker;
      recursive = true;
    };
    ".openclaw/workspace/skills/system-monitor" = {
      source = inputs.plugin-system;
      recursive = true;
    };
    ".openclaw/workspace/skills/filesystem" = {
      source = inputs.plugin-filesystem;
      recursive = true;
    };
    ".openclaw/workspace/skills/process-watch" = {
      source = inputs.plugin-process;
      recursive = true;
    };
  };

  # Disable the document guard to allow overwriting existing files
  home.activation.openclawDocumentGuard = lib.mkForce (lib.hm.dag.entryBefore [ "writeBoundary" ] "");

  # Inject system and user profile paths into the OpenClaw gateway service
  systemd.user.services.openclaw-gateway.Service.Environment = lib.mkForce [
    "HOME=/home/salhashemi2"
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

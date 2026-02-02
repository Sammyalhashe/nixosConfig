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
    skills = [
      {
        name = "coding-agent";
        mode = "copy";
        source = "${inputs.plugin-coding}";
      }
    ];
    documents = ../.;
    config = {
      channels.telegram = {
        tokenFile = "/run/agenix/telegram-bot-token";
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
    };
    instances.default = {
      enable = true;
      config = {
        agents.defaults = {
          skipBootstrap = true;
          model.primary = "google/gemini-3.0-pro";
          # model.primary = "ollama/qwen2.5-coder:14b";
        };
        gateway = {
          mode = lib.mkForce "local";
          auth.token = "temporary-token-123456";
        };
        models = {
          providers = {
            google = {
              api = "google-generative-ai";
              apiKey = "***REMOVED***";
              baseUrl = "https://generativelanguage.googleapis.com/v1beta";
              auth = "api-key";
              models = [
                {
                  id = "gemini-3.0-pro";
                  name = "Gemini 3.0 Pro";
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
                  id = "qwen2.5-coder:14b"; # Matches your 'ollama list' exactly
                  name = "Qwen 2.5 Coder 14B";
                }
              ];
            };
          };
        };
      };
    };
  };

  # Disable the document guard to allow overwriting existing files
  home.activation.openclawDocumentGuard = lib.mkForce (lib.hm.dag.entryBefore [ "writeBoundary" ] "");

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

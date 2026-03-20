{
  config,
  lib,
  pkgs,
  osConfig ? { },
  ...
}:
let
  hostname = osConfig.networking.hostName or "unknown";
  inferenceHost = if hostname == "mothership" then "127.0.0.1" else "11.125.37.101";
in
{
  programs.opencode = {
    enable = true;
    settings = {
      provider = {
        openrouter = {
          name = "openrouter/free";
          npm = "@ai-sdk/openai-compatible";
          options = {
            baseUrl = "https://openrouter.ai/api/v1";
            apiKey = "env:OPENROUTER_API_KEY";
          };
          models = {
            "openrouter/free" = {
              name = "Auto-Free Router";
            };
            "openrouter/aurora-alpha" = {
              name = "Aurora Alpha";
            };
            "openrouter/amazon-canada-ai/nova" = {
              name = "Amazon Nova";
            };
            "openrouter/qwen/qwen-2.5-7b-instruct" = {
              name = "Qwen 2.5 7B";
            };
          };
        };
        mothership = {
          npm = "@ai-sdk/openai-compatible";
          name = "Mothership (LiteLLM)";
          options = {
            baseURL = "http://${inferenceHost}:4000/v1";
          };
          models = {
            "gpt-oss-120b" = {
              name = "GPT-OSS 120B";
            };
          };
        };
      };
      model = "mothership/gpt-oss-120b";
    };
  };

  home.file.".config/opencode/oh-my-opencode.json".text = ''
    {
      "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json",
      "google_auth": false,
      "categories": {
        "quick": {
          "model": "openrouter/amazon-canada-ai/nova"
        },
        "visual-engineering": {
          "model": "openrouter/aurora-alpha"
        },
        "deep": {
          "model": "openrouter/openrouter/free"
        },
        "ultrabrain": {
          "model": "openrouter/openrouter/free"
        },
        "general": {
          "model": "openrouter/qwen/qwen-2.5-7b-instruct"
        }
      },
      "agents": {
        "Sisyphus": {
          "model": "mothership/gpt-oss-120b"
        },
        "Sisyphus-Junior": {
          "model": "mothership/gpt-oss-120b"
        },
        "Prometheus (Planner)": {
          "model": "openrouter/openrouter/free"
        },
        "Prometheus": {
          "model": "openrouter/openrouter/free"
        },
        "oracle": {
          "model": "openrouter/aurora-alpha"
        },
        "explore": {
          "model": "openrouter/openrouter/free"
        },
        "librarian": {
          "model": "openrouter/openrouter/free"
        },
        "code-reviewer": {
          "model": "openrouter/amazon-canada-ai/nova"
        }
      }
    }
  '';
}

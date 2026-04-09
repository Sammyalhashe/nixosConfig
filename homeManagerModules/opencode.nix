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
            baseURL = "https://openrouter.ai/api/v1";
            apiKey = "env:OPENROUTER_API_KEY";
          };
          models = {
            "openrouter/free" = {
              name = "Auto-Free Router";
            };
            "openrouter/qwen/qwen2.5-vl-72b-instruct:free" = {
              name = "Qwen 2.5 VL 72B (Free)";
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
            apiKey = "any";
          };
          models = {
            "qwen3-coder-next" = {
              name = "Qwen3 Coder Next";
            };
          };
        };
        opencode = {
          name = "OpenCode Free";
          npm = "@ai-sdk/openai-compatible";
          options = {
            baseURL = "https://opencode.ai/v1";
            apiKey = "any";
          };
          models = {
            "mimo-v2-omni-free" = {
              name = "MiMo V2 Omni Free";
            };
            "mimo-v2-pro-free" = {
              name = "MiMo V2 Pro Free";
            };
          };
        };
      };
      model = "mothership/qwen3-coder-next";
    };
  };

  home.file.".config/opencode/oh-my-opencode.json".text = ''
    {
      "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json",
      "google_auth": false,
      "categories": {
        "quick": {
          "model": "openrouter/qwen/qwen-2.5-7b-instruct"
        },
        "visual-engineering": {
          "model": "openrouter/qwen/qwen2.5-vl-72b-instruct:free"
        },
        "deep": {
          "model": "openrouter/openrouter/free"
        },
        "ultrabrain": {
          "model": "openrouter/openrouter/free"
        },
        "general": {
          "model": "openrouter/qwen/qwen-2.5-7b-instruct"
        },
        "omni": {
          "model": "opencode/mimo-v2-omni-free"
        }
      },
      "agents": {
        "Sisyphus": {
          "model": "mothership/qwen3-coder-next"
        },
        "Sisyphus-Junior": {
          "model": "mothership/qwen3-coder-next"
        },
        "Prometheus (Planner)": {
          "model": "openrouter/openrouter/free"
        },
        "Prometheus": {
          "model": "openrouter/openrouter/free"
        },
        "oracle": {
          "model": "openrouter/qwen/qwen2.5-vl-72b-instruct:free"
        },
        "explore": {
          "model": "openrouter/openrouter/free"
        },
        "librarian": {
          "model": "openrouter/openrouter/free"
        },
        "code-reviewer": {
          "model": "openrouter/openrouter/free"
        },
        "MiMo": {
          "model": "opencode/mimo-v2-omni-free"
        }
      }
    }
  '';
}

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
            # Vision + multimodal (10M ctx, MoE 17B/109B)
            "meta-llama/llama-4-scout:free" = {
              name = "Llama 4 Scout (Free)";
            };
            # Vision + multimodal, stronger reasoning (1M ctx, MoE 17B/400B)
            "meta-llama/llama-4-maverick:free" = {
              name = "Llama 4 Maverick (Free)";
            };
            # Best free code model (128k ctx)
            "qwen/qwen-2.5-coder-32b-instruct:free" = {
              name = "Qwen 2.5 Coder 32B (Free)";
            };
            # Best free reasoning model (163k ctx, chain-of-thought)
            "deepseek/deepseek-r1:free" = {
              name = "DeepSeek R1 (Free)";
            };
            # Fast multimodal (1M ctx)
            "google/gemini-2.0-flash-exp:free" = {
              name = "Gemini 2.0 Flash Exp (Free)";
            };
            # Reliable general-purpose vision (131k ctx)
            "qwen/qwen2.5-vl-72b-instruct:free" = {
              name = "Qwen 2.5 VL 72B (Free)";
            };
            "qwen/qwen-2.5-7b-instruct" = {
              name = "Qwen 2.5 7B";
            };
          };
        };
        # Groq: fastest free inference (~30 RPM, LPU hardware, no credit card)
        groq = {
          name = "Groq (Free)";
          npm = "@ai-sdk/openai-compatible";
          options = {
            baseURL = "https://api.groq.com/openai/v1";
            apiKey = "env:GROQ_API_KEY";
          };
          models = {
            # Best option: 10M ctx, multimodal, MoE 17B active
            "llama-4-scout-17b-16e-instruct" = {
              name = "Llama 4 Scout (Groq)";
            };
            # Strong general-purpose, multilingual
            "llama-3.3-70b-versatile" = {
              name = "Llama 3.3 70B (Groq)";
            };
            # Fast small model for quick tasks
            "llama-3.1-8b-instant" = {
              name = "Llama 3.1 8B (Groq)";
            };
          };
        };
        mothership = {
          npm = "@ai-sdk/openai-compatible";
          name = "Mothership (LiteLLM)";
          options = {
            baseUrl = "http://${inferenceHost}:4000/v1";
            apiKey = "any";
          };
          models = {
            "qwen3-coder-next" = {
              name = "Qwen3 Coder Next";
            };
            "gemma-4" = {
              name = "Gemma 4 26B";
            };
          };
        };
        zen = {
          name = "OpenCode Zen";
          npm = "@ai-sdk/openai-compatible";
          options = {
            baseUrl = "https://opencode.ai/v1";
            apiKey = "any";
          };
          models = {
            "big-pickle" = {
              name = "Big Pickle Free";
            };
            "mini-max" = {
              name = "MiniMax M2.5 Free";
            };
            "mimo-v2-omni-free" = {
              name = "MiMo V2 Omni Free";
            };
            "mimo-v2-pro-free" = {
              name = "MiMo V2 Pro Free";
            };
            "nemotron-3-super-free" = {
              name = "Nemotron 3 Super Free";
            };
            "qwen-3.6-plus-free" = {
              name = "Qwen 3.6 Plus Free";
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
          "model": "groq/llama-4-scout-17b-16e-instruct"
        },
        "visual-engineering": {
          "model": "openrouter/meta-llama/llama-4-maverick:free"
        },
        "deep": {
          "model": "openrouter/deepseek/deepseek-r1:free"
        },
        "ultrabrain": {
          "model": "openrouter/deepseek/deepseek-r1:free"
        },
        "general": {
          "model": "groq/llama-3.3-70b-versatile"
        },
        "omni": {
          "model": "zen/mimo-v2-omni-free"
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
          "model": "openrouter/deepseek/deepseek-r1:free"
        },
        "Prometheus": {
          "model": "openrouter/deepseek/deepseek-r1:free"
        },
        "oracle": {
          "model": "openrouter/meta-llama/llama-4-maverick:free"
        },
        "explore": {
          "model": "groq/llama-4-scout-17b-16e-instruct"
        },
        "librarian": {
          "model": "groq/llama-3.3-70b-versatile"
        },
        "code-reviewer": {
          "model": "openrouter/qwen/qwen-2.5-coder-32b-instruct:free"
        },
        "MiMo": {
          "model": "zen/mimo-v2-omni-free"
        }
      }
    }
  '';
}

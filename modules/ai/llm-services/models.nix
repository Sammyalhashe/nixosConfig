{
  config,
  lib,
  ...
}:

let
  inherit (lib) mkOption types;

  cfg = config.services.llm-services;
  enabled = lib.filterAttrs (_: m: m.enable) cfg.models;

  # Emit a flag only when its option is set, so a model that says nothing about
  # (say) sampling gets llama-server's own defaults rather than ours.
  optFlag = flag: value: lib.optional (value != null) "${flag} ${toString value}";

  modelArgs =
    m:
    if m.hfRepo != null then
      [
        "--hf-repo ${m.hfRepo}"
        "--hf-file ${m.hfFile}"
      ]
    else
      [ "--model ${m.modelPath}" ];

  execStart =
    m:
    lib.concatStringsSep " " (
      # llama.cpp build (ROCm or Vulkan) is selected by
      # services.llm-services.backend — see ./backend.
      [ "${cfg.backend.package}/bin/llama-server" ]
      ++ modelArgs m
      ++ [
        "--port ${toString m.port}"
        "--host 0.0.0.0"
        "--n-gpu-layers 999"
        "--ctx-size ${toString m.ctxSize}"
        "--parallel ${toString m.parallel}"
        "--threads ${toString m.threads}"
        "--flash-attn 1"
      ]
      ++ optFlag "--cache-type-k" m.kvCacheType
      ++ optFlag "--cache-type-v" m.kvCacheType
      ++ optFlag "--batch-size" m.batchSize
      ++ optFlag "--ubatch-size" m.ubatchSize
      ++ lib.optional m.jinja "--jinja"
      ++ optFlag "--reasoning" m.reasoning
      ++ optFlag "--reasoning-format" m.reasoningFormat
      ++ optFlag "--reasoning-budget" m.reasoningBudget
      ++ optFlag "--temp" m.sampling.temp
      ++ optFlag "--top-p" m.sampling.topP
      ++ optFlag "--top-k" m.sampling.topK
      ++ optFlag "--min-p" m.sampling.minP
      ++ optFlag "--presence-penalty" m.sampling.presencePenalty
      ++ m.extraFlags
      # MANDATORY for Strix Halo to prevent paging stalls.
      ++ [ "--load-mode none" ]
    );

  mkService = name: m: {
    name = "llama-cpp-${name}";
    value = {
      description = "LLaMA C++ server (${m.description} - Port ${toString m.port})";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        XDG_CACHE_HOME = "/var/cache/llama-cpp-${name}";
        LLAMA_CACHE = cfg.modelCacheDir;
      }
      // cfg.backend.environment;

      serviceConfig = {
        User = config.host.username;
        Group = "users";
        StateDirectory = "llama-cpp-models";
        CacheDirectory = "llama-cpp-${name}";
        DeviceAllow = [
          "/dev/dri/renderD128"
          "/dev/dri/card0"
          "/dev/kfd"
        ];
        PrivateDevices = false;

        ExecStart = execStart m;

        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };

  modelModule =
    { name, ... }:
    {
      options = {
        enable = lib.mkEnableOption "the ${name} llama-server instance";

        description = mkOption {
          type = types.str;
          default = name;
          description = "Human-readable name used in the systemd unit description.";
        };

        role = mkOption {
          type = types.enum [
            "utility"
            "coding-agent"
            "reasoning"
            "vision"
          ];
          description = ''
            What this model is for. Purely descriptive today, but it is the
            answer to "which of these should I be calling?" and keeps the
            registry self-documenting as models come and go.
          '';
        };

        port = mkOption {
          type = types.port;
          description = "Port llama-server listens on. Must be unique across enabled models.";
        };

        hfRepo = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            HuggingFace repo passed to llama-server --hf-repo. Preferred over
            modelPath: llama-server reads split.count from the first shard and
            pulls the rest, so a split GGUF can never end up half-present under
            the wrong name. Set to null to load a local file from modelPath.
          '';
        };

        hfFile = mkOption {
          type = types.str;
          default = "";
          description = "GGUF within hfRepo; the *first* shard for split quants. Ignored when hfRepo is null.";
        };

        modelPath = mkOption {
          type = types.str;
          default = "";
          description = "Local GGUF path, used only when hfRepo is null.";
        };

        ctxSize = mkOption {
          type = types.ints.positive;
          description = "Context window. The KV cache is real memory -- see backend.gttSizeMiB.";
        };

        threads = mkOption {
          type = types.ints.positive;
          default = 8;
          description = "CPU threads. Kept low to limit CPU/GPU bus contention.";
        };

        parallel = mkOption {
          type = types.ints.positive;
          default = 1;
          description = "Concurrent request slots.";
        };

        kvCacheType = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "q8_0";
          description = "Quantization for the K/V cache. Set on large-context models to stop the cache dominating memory.";
        };

        batchSize = mkOption {
          type = types.nullOr types.ints.positive;
          default = null;
          description = "Logical batch size; raises prefill throughput on long prompts.";
        };

        ubatchSize = mkOption {
          type = types.nullOr types.ints.positive;
          default = null;
          description = "Physical batch size.";
        };

        jinja = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Use the GGUF's embedded chat template. Required for models whose
            tool-call syntax llama.cpp does not handle natively -- without it
            tool calls are never parsed into OpenAI-shaped `tool_calls`.
          '';
        };

        reasoning = mkOption {
          type = types.nullOr (
            types.enum [
              "on"
              "off"
              "auto"
            ]
          );
          default = null;
          description = "Sets the enable_thinking template kwarg. Null leaves llama-server's default.";
        };

        reasoningFormat = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "deepseek";
          description = ''
            Where thoughts are returned. "deepseek" puts them in
            message.reasoning_content instead of leaving them in
            message.content, which is what keeps tool-call parsing clean for
            agent harnesses.
          '';
        };

        reasoningBudget = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "Token budget for thinking: -1 unrestricted, 0 immediate end, N>0 a cap.";
        };

        sampling = {
          temp = mkOption {
            type = types.nullOr types.float;
            default = null;
          };
          topP = mkOption {
            type = types.nullOr types.float;
            default = null;
          };
          topK = mkOption {
            type = types.nullOr types.int;
            default = null;
          };
          minP = mkOption {
            type = types.nullOr types.float;
            default = null;
          };
          presencePenalty = mkOption {
            type = types.nullOr types.float;
            default = null;
          };
        };

        aliases = mkOption {
          type = types.attrsOf (types.attrsOf types.anything);
          default = { };
          example = lib.literalExpression ''
            {
              "qwen3.8" = { };
              "qwen3.8-fast".extra_body.chat_template_kwargs.enable_thinking = false;
            }
          '';
          description = ''
            LiteLLM model_name -> extra litellm_params merged into the generated
            route. Because the routes are derived from this registry, an alias
            cannot name a model that is not running.
          '';
        };

        extraFlags = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Additional llama-server flags appended verbatim.";
        };
      };
    };
in
{
  options.services.llm-services.models = mkOption {
    type = types.attrsOf (types.submodule modelModule);
    default = { };
    description = ''
      Registry of llama-server instances. Each entry generates a
      llama-cpp-<name> systemd service and its LiteLLM routes, so the proxy and
      the running services cannot drift apart.
    '';
  };

  config = lib.mkIf (enabled != { }) {
    assertions = [
      {
        assertion =
          let
            ports = lib.mapAttrsToList (_: m: m.port) enabled;
          in
          ports == lib.unique ports;
        message = ''
          services.llm-services.models: enabled models must have unique ports.
          Got: ${lib.concatStringsSep ", " (lib.mapAttrsToList (n: m: "${n}=${toString m.port}") enabled)}
        '';
      }
    ];

    systemd.services = lib.mapAttrs' mkService enabled;
  };
}

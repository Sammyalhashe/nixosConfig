{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption types;

  cfg = config.services.llm-services.litellm;
  top = config.services.llm-services;

  enabled = lib.filterAttrs (_: m: m.enable) top.models;

  # One LiteLLM route per alias per enabled model. Deriving these from the
  # registry is the point: a route cannot name a model that is not running.
  localModels = lib.flatten (
    lib.mapAttrsToList (
      name: m:
      lib.mapAttrsToList (alias: extra: {
        model_name = alias;
        litellm_params = {
          model = "openai/${name}";
          api_base = "http://127.0.0.1:${toString m.port}/v1";
          api_key = "none";
        }
        // extra;
      }) m.aliases
    ) enabled
  );

  configFile = pkgs.writeText "litellm-config.yaml" (
    # YAML is a superset of JSON, so LiteLLM parses this directly.
    builtins.toJSON {
      model_list = localModels ++ cfg.extraModels;
      inherit (cfg) litellm_settings router_settings;
    }
  );
in
{
  options.services.llm-services.litellm = {
    enable = lib.mkEnableOption "LiteLLM Proxy Service (Port 4000)";

    extraModels = mkOption {
      type = types.listOf (types.attrsOf types.anything);
      default = [ ];
      description = ''
        Routes appended verbatim to the generated model_list. For upstreams that
        are not local llama-server instances and so cannot come from the model
        registry.
      '';
    };

    litellm_settings = mkOption {
      type = types.attrsOf types.anything;
      default = {
        drop_params = true;
        modify_params = true;
        set_verbose = false;
        cors_allow_origins = [ "*" ];
        cache = true;
        cache_params.cache_type = "local";
      };
      description = "The litellm_settings block of the generated config.";
    };

    router_settings = mkOption {
      type = types.attrsOf types.anything;
      default = {
        routing_strategy = "latency-based-routing";
        enable_pre_call_checks = true;
      };
      description = "The router_settings block of the generated config.";
    };

    configFile = mkOption {
      type = types.path;
      internal = true;
      default = configFile;
      description = "The generated config, exposed for inspection and testing.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.litellm = {
      description = "LiteLLM Proxy Server (Master Router)";
      # Derived from the registry so this can never order against a unit that
      # is not enabled.
      after = [ "network.target" ] ++ lib.mapAttrsToList (name: _: "llama-cpp-${name}.service") enabled;
      wantedBy = [ "multi-user.target" ];
      environment = {
        PORT = "4000";
        HOST = "0.0.0.0";
      };
      serviceConfig = {
        User = config.host.username;
        Group = "users";
        ExecStart =
          let
            # nixpkgs pins litellm at 1.102.1; pin it forward to 1.104.0 (latest
            # stable upstream as of 2026-10-07) until nixpkgs catches up. The
            # Rust bridge (litellm-rust/) moves in lockstep with the Python
            # source, so its vendored Cargo deps have to be rebuilt against the
            # new src too. `optional-dependencies.proxy` is left as nixpkgs
            # defines it for 1.102.1: the packages upstream added to that extra
            # for 1.104.0 (granian, hiredis, starlette, litellm-proxy-extras,
            # litellm-enterprise, pyroscope-io) are all behind CLI flags we don't
            # pass, a DATABASE_URL/Prisma path we don't use, or a try/except
            # ImportError — verified against the 1.104.0 source, not just
            # assumed. Drop this whole override once nixpkgs ships >=1.104.0.
            litellm =
              ps:
              ps.litellm.overridePythonAttrs (old: rec {
                version = "1.104.0";
                src = pkgs.fetchFromGitHub {
                  owner = "BerriAI";
                  repo = "litellm";
                  tag = "v${version}";
                  hash = "sha256-HhDp6ddfe/355/NZUmDHhcG75eLLXjwY61bQVWFk2Ks=";
                };
                cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
                  inherit (old) pname cargoRoot;
                  inherit version src;
                  # crates.io is unreachable from the host this pin was prepared
                  # on (corporate proxy blocks it outright), so this could not be
                  # prefetched. Replace with the real hash nix reports in the
                  # "got:" line the first time this builds on a host with normal
                  # network access.
                  hash = pkgs.lib.fakeHash;
                };
              });
            # Use litellm's own `proxy` optional-dependencies from nixpkgs
            # (equivalent to the PyPI `litellm[proxy]` extra) rather than a
            # hand-maintained package list — reproducible and always in sync
            # with the packaged litellm version.
            pythonEnv = pkgs.python313.withPackages (
              ps: [ (litellm ps) ] ++ (litellm ps).optional-dependencies.proxy
            );
          in
          "${pythonEnv}/bin/litellm --config ${configFile} --port 4000 --host 0.0.0.0";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}

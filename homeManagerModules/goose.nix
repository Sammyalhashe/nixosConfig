{ pkgs, lib, config, ... }:
let
  # Goose rewrites config.yaml itself, so these are merged in, not owned.
  extensions = {
    seats-aero = {
      type = "streamable_http";
      name = "seats-aero";
      description = "Award flight availability from seats.aero (anonymous access)";
      enabled = true;
      uri = "https://seats.aero/mcp";
      headers = { };
      env_keys = [ ];
      envs = { };
      timeout = 300;
    };
  };
  extensionsYaml = (pkgs.formats.yaml { }).generate "goose-extensions.yaml" extensions;
in
{
  home.packages = [
    pkgs.goose-cli
    # Goose against the public mesh client on localhost:9337; "mesh" lets the
    # mesh pick the model. Peers see the prompts, and their models are
    # untrusted, so every tool call needs approval.
    (pkgs.writeShellScriptBin "goose-mesh" ''
      export GOOSE_PROVIDER=openai
      export OPENAI_HOST=http://localhost:9337
      export OPENAI_BASE_PATH=v1/chat/completions
      export OPENAI_API_KEY=mesh
      export GOOSE_MODEL="''${GOOSE_MODEL:-mesh}"
      export GOOSE_MODE=approve
      exec ${pkgs.goose-cli}/bin/goose "$@"
    '')
  ];

  # Adds each extension only if missing, so changes made in Goose survive.
  home.activation.gooseExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    config="${config.xdg.configHome}/goose/config.yaml"
    run mkdir -p "$(dirname "$config")"
    [ -e "$config" ] || run touch "$config"
    run ${pkgs.yq-go}/bin/yq -i \
      '.extensions = (load("${extensionsYaml}") * (.extensions // {})) | (.extensions | ..) style=""' \
      "$config"
  '';
}

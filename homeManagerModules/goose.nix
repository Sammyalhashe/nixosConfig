{ pkgs, lib, config, osConfig, ... }:
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
    fastmail = {
      type = "streamable_http";
      name = "fastmail";
      description = "Fastmail mail, contacts and calendars";
      enabled = true;
      uri = "https://api.fastmail.com/mcp";
      headers.Authorization = "Bearer \${FASTMAIL_API_KEY}";
      env_keys = [ "FASTMAIL_API_KEY" ];
      envs = { };
      timeout = 300;
    };
  };
  fastmailKey = osConfig.sops.secrets.fastmail_hermes_api_key.path;
  extensionsYaml = (pkgs.formats.yaml { }).generate "goose-extensions.yaml" extensions;
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "goose" ''
      if [ -r ${fastmailKey} ]; then
        FASTMAIL_API_KEY=$(< ${fastmailKey})
        export FASTMAIL_API_KEY
      fi
      exec ${pkgs.goose-cli}/bin/goose "$@"
    '')
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
      # Mesh models are strangers' machines; they must not reach your mail.
      unset FASTMAIL_API_KEY
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

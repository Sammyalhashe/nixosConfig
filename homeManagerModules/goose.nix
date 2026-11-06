{ pkgs, ... }:
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
}

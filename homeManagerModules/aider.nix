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

  aiderConfig = {
    # Use our local LiteLLM Proxy endpoint
    openai-api-base = "http://${inferenceHost}:4000/v1";
    openai-api-key = "none";

    # Use openai/ prefix so LiteLLM knows the provider for routing
    model = "openai/qwen3.6";
    editor-model = "openai/qwen3.6";
    weak-model = "openai/qwen-flash";

    # Always auto-commit changes (optional, but good for workflow)
    auto-commits = true;

    # Don't check for updates constantly
    check-update = false;
  };
in
{
  options.programs.aider = {
    enable = lib.mkEnableOption "aider configuration";
  };

  config = lib.mkIf config.programs.aider.enable {
    home.packages = [ pkgs.aider-chat-full ];

    # Write the configuration file to the home directory
    # Aider looks for .aider.conf.yml in the home directory or git root
    home.file.".aider.conf.yml".text = lib.generators.toYAML { } aiderConfig;
  };
}

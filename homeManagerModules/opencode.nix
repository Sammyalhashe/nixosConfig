{
  config,
  lib,
  pkgs,
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
}

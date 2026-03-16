{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.opencode = {
    enable = true;
    settings = {
      provider = {
        mothership = {
          npm = "@ai-sdk/openai-compatible";
          name = "Mothership (LiteLLM)";
          options = {
            baseURL = "http://127.0.0.1:4000/v1";
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

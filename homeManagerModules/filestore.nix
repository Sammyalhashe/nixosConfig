{
  inputs,
  lib,
  ...
}:
{
  imports = [
    ./zellij.nix
    ./nushell.nix
    ./wsl.nix
    inputs.nix-openclaw.homeManagerModules.openclaw
  ];

  programs.openclaw = {
    enable = true;
    documents = ../.;
    instances.default = {
      enable = true;
      config = {
        agents.defaults = {
          skipBootstrap = true;
          model.primary = "gemini/gemini-1.5-pro";
        };
        gateway = {
          mode = lib.mkForce "local";
          auth.token = "temporary-token-123456";
        };
        models = {
          providers = {
            gemini = {
              api = "google-generative-ai";
              apiKey = "YOUR_GEMINI_API_KEY"; # TODO: Use sops or env var
              baseUrl = "https://generativelanguage.googleapis.com";
              auth = "api-key";
              models = [
                {
                  id = "gemini-1.5-pro";
                  name = "Gemini 1.5 Pro";
                }
              ];
            };
            ollama = {
              api = "openai-responses";
              baseUrl = "http://11.125.37.135:11434/v1";
              apiKey = "ollama"; # placeholder
              models = [
                {
                  id = "deepseek-coder-v2:16b";
                  name = "DeepSeek Coder V2 (Ollama)";
                }
                {
                  id = "qwen3:8b";
                  name = "Qwen 3 (Ollama)";
                }
                {
                  id = "MFDoom/deepseek-coder-v2-tool-calling:16b";
                  name = "DeepSeek Coder V2 Tool Calling (Ollama)";
                }
              ];
            };
          };
        };
      };
    };
  };

  # Disable the document guard to allow overwriting existing files
  home.activation.openclawDocumentGuard = lib.mkForce (lib.hm.dag.entryBefore [ "writeBoundary" ] "");

  programs.starship.enable = true;
  programs.git = {
    enable = true;
    settings = {
      user.name = "Sammy Al Hashemi";
      user.email = "sammy@salh.xyz";
    };
  };
  home.stateVersion = "23.11";
}

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
          model.primary = "ollama/qwen2.5-coder:14b";
        };
        gateway = {
          mode = lib.mkForce "local";
          auth.token = "temporary-token-123456";
        };
        models = {
          providers = {
            gemini = {
              api = "google-generative-ai";
              apiKey = "***REMOVED***";
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
                  id = "qwen2.5-coder:14b";
                  name = "Qwen 2.5 Coder 14B (Ollama)";
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

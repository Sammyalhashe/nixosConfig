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

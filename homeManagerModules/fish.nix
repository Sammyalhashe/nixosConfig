{ config, lib, ... }:
let
  nushellOnly = [
    "fg"
    "pop"
    "pops"
  ];
in
{
  # modules/shell/default.nix reads this to make fish the login shell.
  options.shells.fish.enable = lib.mkEnableOption "fish as the login shell, with the nushell aliases";

  config = lib.mkIf config.shells.fish.enable {
    programs.fish = {
      enable = true;
      shellAliases = removeAttrs config.programs.nushell.shellAliases nushellOnly // {
        pop = "env RESEND_API_KEY=(skate get pop-resend-key@api-keys | string trim) pop";
        pops = "env RESEND_API_KEY=(skate get pop-resend-key@api-keys | string trim) pop --from sammy@salh.xyz";
      };
      shellInit = ''
        set -q EDITOR; or set -gx EDITOR nvim
        set -gx ANTHROPIC_BASE_URL http://11.125.37.101:4000
        set -gx ANTHROPIC_API_KEY sk-no-key-required
        test -r /run/secrets/perplexity_api_key; and set -gx PERPLEXITY_API_KEY (string trim < /run/secrets/perplexity_api_key)
        test -r /run/secrets/openrouter_api_key; and set -gx OPENROUTER_API_KEY (string trim < /run/secrets/openrouter_api_key)
        test -r /run/secrets/gemini_api_key; and set -gx GEMINI_API_KEY (string trim < /run/secrets/gemini_api_key)
      '';
    };

    # Ryoku materializes its own read-only config.fish, so home-manager's goes
    # into conf.d, which fish loads first on every host.
    xdg.configFile."fish/config.fish".enable = false;
    xdg.configFile."fish/conf.d/home-manager.fish".source =
      config.xdg.configFile."fish/config.fish".source;
  };
}

{
  config,
  pkgs,
  ...
}:
let
  # Not in rycee's set, so this pins the signed AMO build; bump version, url and
  # sha256 together (https://addons.mozilla.org/firefox/addon/send-to-ntfy/).
  send-to-ntfy = pkgs.nur.repos.rycee.firefox-addons.buildFirefoxXpiAddon {
    pname = "send-to-ntfy";
    version = "3.1.1";
    addonId = "{cad379db-edfe-4c5e-b936-27a19156b5dc}";
    url = "https://addons.mozilla.org/firefox/downloads/file/5174960/send_to_ntfy-3.1.1.xpi";
    sha256 = "60f998ea2a6c078e598870a95c8849b1d00612f7425f26f31f815066f2674858";
    meta = {
      license = pkgs.lib.licenses.gpl3Only;
      platforms = pkgs.lib.platforms.all;
    };
  };
in
{
  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [
      pkgs.kdePackages.plasma-browser-integration
    ];
    profiles.default = {
      name = "default";
      isDefault = true;
      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        bitwarden
        sponsorblock
        darkreader
        metamask
        floccus
        send-to-ntfy
      ];
      search = {
        force = true;
        default = "Brave";
        privateDefault = "Brave";

        engines = {
          "Nix Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [
              "@nix"
              "@np"
            ];
          };
          "Nix Options" = {
            urls = [
              {
                template = "https://search.nixos.org/options";
                params = [
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@no" ];
          };

          "NixOS Wiki" = {
            urls = [
              {
                template = "https://wiki.nixos.org/w/index.php";
                params = [
                  {
                    name = "search";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@nw" ];
          };
          "Brave" = {
            urls = [
              {
                template = "https://search.brave.com/search?q={searchTerms}";
                definedAliases = [
                  "@br"
                  "@brave"
                ];
              }
            ];
          };
        };
      };
    };
  };
}

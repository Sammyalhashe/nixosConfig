{
  config,
  pkgs,
  ...
}:
{
  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [
      pkgs.kdePackages.plasma-browser-integration
    ];
    # configPath is deliberately NOT set. It is `internal = true` in
    # home-manager and its value must be RELATIVE to $HOME — the module builds
    # the XDG default as
    #   lib.removePrefix "${config.home.homeDirectory}/" config.xdg.configHome
    # Setting it to "${config.xdg.configHome}/mozilla/firefox" (as home-manager's
    # own deprecation warning displays it) yields an absolute path, so every
    # home.file key became "/home/<user>/.config/mozilla/firefox/...", which
    # home.file resolves relative to $HOME. profiles.ini and user.js therefore
    # landed somewhere Firefox never reads, and Firefox quietly fell back to a
    # profile of its own making.
    #
    # Left unset, home-manager picks the right path from home.stateVersion:
    # .mozilla/firefox below 26.05, $XDG_CONFIG_HOME/mozilla/firefox at or above
    # it. This host is on 24.05, so .mozilla/firefox — which is where the real
    # profile already lives.
    profiles.default = {
      name = "default";
      isDefault = true;
      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        bitwarden
        sponsorblock
        darkreader
        metamask
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

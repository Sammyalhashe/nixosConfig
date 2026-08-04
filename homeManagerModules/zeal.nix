{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.zeal;

  docsetOpts = types.submodule {
    options = {
      url = mkOption {
        type = types.str;
        description = "URL to the docset tarball (.tgz)";
      };
      hash = mkOption {
        type = types.str;
        description = "SHA-256 hash of the docset archive";
      };
    };
  };
in
{
  options.programs.zeal = {
    enable = mkEnableOption "Zeal offline documentation viewer";

    docsets = mkOption {
      type = types.attrsOf docsetOpts;
      default = { };
      example = literalExpression ''
        {
          Python_3 = {
            url = "https://sanfrancisco.kapeli.com/feeds/Python_3.tgz";
            hash = "sha256-...";
          };
        }
      '';
      description = "Declarative docsets fetched from Dash/Zeal mirrors.";
    };
  };

  config = mkIf cfg.enable {
    # Install the Zeal binary
    home.packages = [ pkgs.zeal ];

    # Extract docsets into Zeal's data directory
    home.file = mapAttrs' (
      name: docset:
      nameValuePair ".local/share/Zeal/Zeal/docsets/${name}.docset" {
        source = pkgs.fetchzip {
          url = docset.url;
          hash = docset.hash;
        };
      }
    ) cfg.docsets;
  };
}

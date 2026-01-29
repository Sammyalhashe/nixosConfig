{ config, lib, ... }:

{
  options.host = {
    username = lib.mkOption {
      type = lib.types.str;
      default = "salhashemi2";
      description = "The username of the primary user.";
    };

    isWsl = lib.mkEnableOption "Whether the host is running in WSL.";

    isHeadless = lib.mkEnableOption "Whether the host is headless (no GUI/Steam).";

    useOmarchy = lib.mkEnableOption "Whether to use Omarchy configuration.";

    greetd = lib.mkEnableOption "Whether to use Greetd.";

    homeManagerHostname = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = "The hostname to use for Home Manager configuration files.";
    };

    setNameservers = lib.mkEnableOption "Whether to explicitly set nameservers via networking.nameservers.";

    fallbackNameservers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "A list of additional nameservers to append as fallbacks.";
    };
  };
}

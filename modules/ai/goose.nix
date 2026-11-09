{ config, ... }:
{
  # Read by the goose wrapper in homeManagerModules/goose.nix for the Fastmail MCP.
  sops.secrets.fastmail_hermes_api_key.owner = config.host.username;

  home-manager.users.${config.host.username}.imports = [ ../../homeManagerModules/goose.nix ];
}

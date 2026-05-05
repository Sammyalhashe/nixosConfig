{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.cloudflare-warp = {
    enable = config.host.enableCloudflareWarp;
  };

  environment.systemPackages = lib.mkIf config.host.enableCloudflareWarp (
    with pkgs;
    [
      cloudflare-warp
    ]
  );
}

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.networking;
in
{
  options.networking.cloudflare-warp = {
    enable = lib.mkEnableOption "home-manager cloudflare warp service enablement";
  };

  config = lib.mkIf cfg.cloudflare-warp.enable {
    home.packages = with pkgs; [
      cloudflare-warp
    ];
  };
}

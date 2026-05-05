{
  pkgs,
  lib,
  config,
  ...
}:
{
  services.adguardhome = {
    enable = true;
    settings = {
      # You can configure everything via the Nix DSL or the Web UI
      http.address = "0.0.0.0:3001";
      dns.bind_hosts = [ "0.0.0.0" ];
    };
  };
}

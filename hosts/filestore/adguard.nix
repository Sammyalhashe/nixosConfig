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
      http.address = "0.0.0.0:3000";
      dns.bind_hosts = [ "11.125.37.98" ];
      dns.port = 53;
    };
  };
}

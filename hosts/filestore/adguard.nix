{
  pkgs,
  lib,
  config,
  ...
}:
let
  lanRewrite = domain: answer: {
    inherit domain answer;
    enabled = true;
  };
in
{
  services.adguardhome = {
    enable = true;
    settings = {
      http.address = "0.0.0.0:3000";
      dns = {
        bind_hosts = [ "11.125.37.98" ];
        port = 53;
        upstream_dns = [ "https://dns10.quad9.net/dns-query" ];
        bootstrap_dns = [
          "9.9.9.10"
          "149.112.112.10"
          "2620:fe::10"
          "2620:fe::fe:10"
        ];
      };
      filters = [
        {
          enabled = true;
          id = 1;
          name = "AdGuard DNS filter";
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
        }
        {
          enabled = true;
          id = 3;
          name = "StevenBlack hosts (Pi-hole default)";
          url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
        }
      ];
      # LAN clients reach these on filestore directly rather than out
      # through the Cloudflare tunnel and back over the upload link.
      filtering.rewrites = [
        (lanRewrite "cloud.salh.xyz" "11.125.37.98")
        (lanRewrite "nginx.salh.xyz" "11.125.37.98")
        (lanRewrite "git.salh.xyz" "11.125.37.98")
        (lanRewrite "vaultwarden.salh.xyz" "11.125.37.98")
        (lanRewrite "filestore.salh.xyz" "11.125.37.98")
        (lanRewrite "homeassistant.salh.xyz" "11.125.37.98")
        (lanRewrite "oldboy.salh.xyz" "11.125.37.175")
        (lanRewrite "mothership.salh.xyz" "11.125.37.101")
      ];
    };
  };
}

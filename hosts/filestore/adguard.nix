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
  # Holds only the bcrypt hash (htpasswd -nB). The repo is public, so it
  # is merged into AdGuardHome.yaml at start instead of living in settings.
  sops.secrets.adguard_admin_password_hash = { };
  sops.templates."adguard-users.yaml".content = builtins.toJSON {
    users = [
      {
        name = config.host.username;
        password = config.sops.placeholder.adguard_admin_password_hash;
      }
    ];
  };

  systemd.services.adguardhome = {
    serviceConfig.LoadCredential = [
      "users.yaml:${config.sops.templates."adguard-users.yaml".path}"
    ];
    preStart = lib.mkAfter ''
      ${lib.getExe pkgs.yaml-merge} "$STATE_DIRECTORY/AdGuardHome.yaml" "$CREDENTIALS_DIRECTORY/users.yaml" \
        > "$STATE_DIRECTORY/AdGuardHome.yaml.tmp"
      mv "$STATE_DIRECTORY/AdGuardHome.yaml.tmp" "$STATE_DIRECTORY/AdGuardHome.yaml"
      chmod 600 "$STATE_DIRECTORY/AdGuardHome.yaml"
    '';
  };

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

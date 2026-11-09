{ config, ... }:
let
  secret = config.sops.placeholder;
in
{
  # Published by the remote-managed picloud tunnel: its public hostname
  # ntfy.salh.xyz must point at http://localhost:2586 in the Cloudflare dashboard.
  services.ntfy-sh = {
    enable = true;
    environmentFile = config.sops.templates."ntfy-env".path;
    settings = {
      base-url = "https://ntfy.salh.xyz";
      listen-http = "127.0.0.1:2586";
      behind-proxy = true;
      auth-file = "/var/lib/ntfy-sh/user.db";
      auth-default-access = "deny-all";
      # iOS gets pushes through ntfy.sh, which only ever sees message IDs.
      upstream-base-url = "https://ntfy.sh";
    };
  };

  sops.secrets.NTFY_USER_HASH = { };
  sops.secrets.NTFY_REPORTER_USER_HASH = { };
  sops.secrets.NTFY_JOB_TOKEN = { };
  sops.secrets.NTFY_ALERTS_USER_HASH = { };
  sops.secrets.NTFY_ALERTS_TOKEN = { };
  sops.secrets.NTFY_HERMES_TOKEN = { };

  # Publishers can only write their own topics. alerts has one token per
  # client (hosts, Hermes) so either can be revoked alone.
  # systemd reads this as root before starting ntfy's DynamicUser.
  sops.templates."ntfy-env" = {
    # ntfy reads users and tokens only at startup.
    restartUnits = [ "ntfy-sh.service" ];
    content = ''
      NTFY_AUTH_USERS=sammy:${secret.NTFY_USER_HASH}:admin,reporter:${secret.NTFY_REPORTER_USER_HASH}:user,alerts:${secret.NTFY_ALERTS_USER_HASH}:user
      NTFY_AUTH_ACCESS=reporter:portfolio:wo,alerts:alerts:wo,alerts:deploys:wo,alerts:hermes:wo
      NTFY_AUTH_TOKENS=reporter:${secret.NTFY_JOB_TOKEN}:portfolio-report,alerts:${secret.NTFY_ALERTS_TOKEN}:hosts,alerts:${secret.NTFY_HERMES_TOKEN}:hermes
    '';
  };
}

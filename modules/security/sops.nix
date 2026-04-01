{ config, pkgs, ... }:
{
  sops.defaultSopsFile = ../../secrets.yaml;
  sops.age.keyFile = "/var/lib/sops/age/key.txt";
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.age.generateKey = true;

  sops.secrets.gemini_api_key = {
    owner = config.host.username;
  };
  sops.secrets.perplexity_api_key = {
    owner = config.host.username;
  };
  sops.secrets.pop_resend_key = {
    owner = config.host.username;
  };
  sops.secrets.filestore_user_password = { };
  sops.secrets.filestore_password_hash = {
    neededForUsers = true;
  };
  sops.secrets.filestore_container_env = { };
  sops.secrets.filestore_wifi_env = { };
  sops.secrets.filestore_wifi_ssid = { };
  sops.secrets.filestore_wifi_password = { };
  sops.secrets.filestore_authentik_secret = { };
  sops.secrets.filestore_postgres_password = { };
  sops.secrets.vaultwarden_sso_client_secret = { };
  sops.secrets.vaultwarden_admin_token = { };
  sops.secrets.nextcloud_admin_password = { };
  sops.secrets.syncthing_gui_password = { };
  sops.secrets.telegram_bot_token = {
    owner = config.host.username;
  };
  sops.secrets.grafana_telegram_bot_token = {
    key = "telegram_bot_token";
    owner = "grafana";
  };
  sops.secrets.brave_api_key = {
    owner = config.host.username;
  };
  sops.secrets.openrouter_api_key = {
    owner = config.host.username;
  };
  sops.secrets.chainstack_api_key = {
    owner = config.host.username;
  };
  sops.secrets.polyclaw_private_key = {
    owner = config.host.username;
  };
  sops.secrets.nvidia_api_key = {
    owner = config.host.username;
  };
  sops.secrets.eth_rpc_url = {
    owner = config.host.username;
  };
  sops.secrets.eth_private_key = {
    owner = config.host.username;
  };
  sops.secrets.coinbase_api_key_clawdbot = { };
  sops.secrets.coinbase_api_id_clawdbot = { };
  sops.secrets.coinbase_api_secret_clawdbot = { };

  sops.secrets.icloud_email = {
    owner = config.host.username;
  };
  sops.secrets.openclaw_icloud_user = {
    owner = config.host.username;
  };
  sops.secrets.icloud_password = {
    owner = config.host.username;
  };
  sops.secrets.cloudflare_token = {
    owner = config.host.username;
  };

  sops.templates."openclaw-env" = {
    content = ''
      GEMINI_API_KEY=${config.sops.placeholder.gemini_api_key}
      GOOGLE_API_KEY=${config.sops.placeholder.gemini_api_key}
      BRAVE_API_KEY=${config.sops.placeholder.brave_api_key}
      OPENROUTER_API_KEY=${config.sops.placeholder.openrouter_api_key}
      CHAINSTACK_API_KEY=${config.sops.placeholder.chainstack_api_key}
      POLYCLAW_PRIVATE_KEY=${config.sops.placeholder.polyclaw_private_key}
      NVIDIA_API_KEY=${config.sops.placeholder.nvidia_api_key}
      ETH_RPC_URL=${config.sops.placeholder.eth_rpc_url}
      ETH_PRIVATE_KEY=${config.sops.placeholder.eth_private_key}
      POLYGON_RPC_URL=https://polygon-mainnet.core.chainstack.com/cb70f464d151c934637cb3318b1cb66e
      CHAINSTACK_NODE=https://polygon-mainnet.core.chainstack.com/cb70f464d151c934637cb3318b1cb66e

      # Email Skill (iCloud)
      IMAP_HOST=imap.mail.me.com
      IMAP_PORT=993
      IMAP_USER=${config.sops.placeholder.icloud_email}
      IMAP_PASS=${config.sops.placeholder.icloud_password}
      IMAP_TLS=true
      SMTP_HOST=smtp.mail.me.com
      SMTP_PORT=587
      SMTP_USER=${config.sops.placeholder.icloud_email}
      SMTP_PASS=${config.sops.placeholder.icloud_password}
      SMTP_SECURE=false

      # Cloudflare Skill
      CLOUDFLARE_API_TOKEN=${config.sops.placeholder.cloudflare_token}
    '';
    owner = config.host.username;
  };

  sops.templates."coinbase-api-json" = {
    content = ''
      {
         "name": "${config.sops.placeholder.coinbase_api_id_clawdbot}",
         "privateKey": "${config.sops.placeholder.coinbase_api_secret_clawdbot}"
      }
    '';
    owner = config.host.username;
    path = "/home/${config.host.username}/cdb_api_key.json";
  };

  sops.templates."picoclaw-env" = {
    content = ''
      GEMINI_API_KEY=${config.sops.placeholder.gemini_api_key}
      GOOGLE_API_KEY=${config.sops.placeholder.gemini_api_key}
      BRAVE_API_KEY=${config.sops.placeholder.brave_api_key}
      OPENROUTER_API_KEY=${config.sops.placeholder.openrouter_api_key}
      CHAINSTACK_API_KEY=${config.sops.placeholder.chainstack_api_key}
      POLYCLAW_PRIVATE_KEY=${config.sops.placeholder.polyclaw_private_key}
      NVIDIA_API_KEY=${config.sops.placeholder.nvidia_api_key}
      POLYGON_RPC_URL=https://polygon-mainnet.core.chainstack.com/cb70f464d151c934637cb3318b1cb66e
      CHAINSTACK_NODE=https://polygon-mainnet.core.chainstack.com/cb70f464d151c934637cb3318b1cb66e
    '';
    owner = config.host.username;
  };

  sops.templates."open-webui-env" = {
    content = ''
      BRAVE_SEARCH_API_KEY=${config.sops.placeholder.brave_api_key}
      PERPLEXITY_API_KEY=${config.sops.placeholder.perplexity_api_key}
      PERPLEXITY_SEARCH_API_URL=https://api.perplexity.ai/chat/completions
      PERPLEXITY_MODEL=sonar
    '';
  };
}

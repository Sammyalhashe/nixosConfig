{ config, pkgs, ... }:
{
  sops.defaultSopsFile = ../secrets.yaml;
  sops.age.keyFile = "/var/lib/sops/age/key.txt";
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.age.generateKey = true;

  sops.secrets.gemini_api_key = {
    owner = "salhashemi2";
  };
  sops.secrets.perplexity_api_key = {
    owner = "salhashemi2";
  };
  sops.secrets.pop_resend_key = {
    owner = "salhashemi2";
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
    owner = "salhashemi2";
  };
  sops.secrets.brave_api_key = {
    owner = "salhashemi2";
  };
  sops.secrets.openrouter_api_key = {
    owner = "salhashemi2";
  };
  sops.secrets.chainstack_api_key = {
    owner = "salhashemi2";
  };
  sops.secrets.polyclaw_private_key = {
    owner = "salhashemi2";
  };
  sops.secrets.nvidia_api_key = {
    owner = "salhashemi2";
  };
  sops.secrets.coinbase_api_key_clawdbot = { };

  sops.templates."openclaw-env" = {
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
}

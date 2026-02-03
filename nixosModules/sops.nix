{ config, pkgs, ... }:
{
  sops.defaultSopsFile = ../secrets.yaml;
  sops.age.keyFile = "/var/lib/sops/age/key.txt";
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.age.generateKey = true;

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
  sops.secrets.telegram_bot_token = { };
  sops.secrets.coinbase_api_key_clawdbot = { };
}

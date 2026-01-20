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
}

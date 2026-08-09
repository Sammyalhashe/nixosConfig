{ config, ... }:
let
  # All per-host public keys, so root and salhashemi2 can log in passwordless
  # between hosts (starship, mothership, homebase) and deploy-rs can activate.
  hostKeys = builtins.attrValues config.hostKeys;
in
{
  users.users.root.openssh.authorizedKeys.keys = hostKeys ++ [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINUptk+nhbHYTfUJvGT3/X4vkKWRotT5ckw8BiQuADml sammy@salh.xyz"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFZKrkpzxAf0u3+fn59xouUtVHtklRuGwCwfPpR0Y8nc sammy.alhashemi@mail.utoronto.ca"
  ];

  users.users.salhashemi2 = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "sudo"
    ];
    openssh.authorizedKeys.keys = hostKeys;
  };

  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}

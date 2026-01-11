{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (config.host.greetd && !config.host.isWsl) {
    services.greetd = {
      enable = true;
      vt = 3;
      settings = {
        default_session = {
          user = config.host.username;
          command = "hyprland";
        };
      };
    };
  };
}

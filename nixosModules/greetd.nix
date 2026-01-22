{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf config.host.greetd {
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = lib.mkForce "${pkgs.greetd.tuigreet}/bin/tuigreet --time --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions --remember --remember-user-session";
          user = "greeter";
        };
      };
    };
  };
}

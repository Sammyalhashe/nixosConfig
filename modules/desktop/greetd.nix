{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (config.host.enableGreetd && !config.host.isHeadless) {
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          # cosmic-greeter is a Wayland app and needs a compositor (like cage) to run.
          # -s enables VT switching in cage
          command = lib.mkForce "${pkgs.dbus}/bin/dbus-run-session ${pkgs.cage}/bin/cage -s -- ${pkgs.cosmic-greeter}/bin/cosmic-greeter";
          user = "greeter";
        };
      };
    };

    # The greeter requires its daemon to be running for D-Bus communication
    systemd.services.cosmic-greeter-daemon = {
      description = "COSMIC Greeter Daemon";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.cosmic-greeter}/bin/cosmic-greeter-daemon";
        Restart = "always";
      };
    };

    # Ensure the 'greeter' user has necessary permissions for graphics and input
    users.users.greeter = {
      isSystemUser = true;
      group = "greeter";
      extraGroups = [ "video" "input" "render" ];
    };
    users.groups.greeter = {};

    # Ensure cosmic-greeter, cage, and their dependencies are available
    environment.systemPackages = with pkgs; [
      cosmic-greeter
      cage
    ];

    # Required for some Wayland compositors/apps to function correctly
    # especially when run via greetd
    systemd.tmpfiles.rules = [
      "d /run/greetd 0755 greeter greeter -"
    ];
  };
}

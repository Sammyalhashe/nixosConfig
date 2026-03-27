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
          command = lib.mkForce "${pkgs.cosmic-greeter}/bin/cosmic-greeter";
          user = "greeter";
        };
      };
    };

    # Ensure cosmic-greeter and its dependencies are available
    environment.systemPackages = with pkgs; [
      cosmic-greeter
    ];
  };
}

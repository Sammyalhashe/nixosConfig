{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (config.host.enableGreetd && !config.host.isHeadless) {
    # ReGreet is a modern GTK4-based greeter for greetd.
    # The programs.regreet module automatically handles the greetd configuration.
    programs.regreet = {
      enable = true;
      settings = {
        background = {
          # Using one of your existing wallpapers
          path = ../../common/assets/BLACK_VII_desktop.jpg;
          fit = "Cover";
        };
        GTK = {
          theme_name = lib.mkForce "Adwaita-dark";
          cursor_theme_name = lib.mkForce "Adwaita";
          font_name = lib.mkForce "Cantarell 11";
        };
      };
    };

    # Ensure the 'greeter' user has all necessary permissions
    users.users.greeter = {
      extraGroups = [
        "video"
        "input"
        "render"
      ];
    };
  };
}

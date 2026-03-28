{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (config.host.enableGreetd && !config.host.isHeadless) {
    # ReGreet is a modern GTK4-based greeter for greetd.
    programs.regreet = {
      enable = true;
      
      # Use a modern font and theme
      font = {
        package = pkgs.lexend;
        name = "Lexend 12";
      };

      settings = {
        background = {
          # Using one of your existing wallpapers
          path = lib.mkForce ../../common/assets/BLACK_VII_desktop.jpg;
          fit = lib.mkForce "Cover";
        };
        GTK = {
          theme_name = lib.mkForce "adw-gtk3-dark";
          cursor_theme_name = lib.mkForce "Adwaita";
          application_prefer_dark_theme = lib.mkForce true;
        };
        appearance = {
          greeting_msg = lib.mkForce "Welcome back, Sammy";
        };
      };

      # Custom CSS for a modern "Glassmorphism" look
      extraCss = lib.mkForce ''
        /* The main container for the login widgets */
        .main-container {
          background-color: rgba(30, 30, 46, 0.4); /* Semi-transparent */
          backdrop-filter: blur(15px);             /* Frosted glass effect */
          border-radius: 24px;
          border: 1px solid rgba(255, 255, 255, 0.1);
          box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.6);
          padding: 40px;
        }

        /* Style the input fields */
        entry {
          background: rgba(255, 255, 255, 0.05);
          border-radius: 12px;
          border: 1px solid rgba(255, 255, 255, 0.1);
          color: white;
          padding: 12px;
          margin-bottom: 15px;
          font-weight: 500;
        }

        entry:focus {
          border-color: #89b4fa; /* Accent color on focus */
          box-shadow: 0 0 0 2px rgba(137, 180, 250, 0.3);
        }

        /* Style the primary login button */
        button.suggested-action {
          background-color: #89b4fa;
          color: #1e1e2e;
          border-radius: 12px;
          font-weight: 700;
          padding: 12px 24px;
          margin-top: 10px;
        }

        button.suggested-action:hover {
          background-color: #b4befe;
        }

        /* Large, centered clock */
        #clock {
          font-size: 84px;
          font-weight: 800;
          color: rgba(255, 255, 255, 0.9);
          margin-bottom: 30px;
          text-shadow: 0 4px 15px rgba(0,0,0,0.5);
        }

        /* Hide the default window background to show the wallpaper clearly */
        window {
          background: transparent;
        }

        /* Style the dropdowns */
        combobox {
          background: rgba(255, 255, 255, 0.1);
          border-radius: 12px;
          color: white;
          padding: 8px;
        }
      '';
    };

    # Ensure the 'greeter' user has all necessary permissions
    users.users.greeter = {
      extraGroups = [
        "video"
        "input"
        "render"
      ];
    };

    # Add necessary packages for the theme/font
    environment.systemPackages = with pkgs; [
      lexend
      adw-gtk3
    ];
  };
}

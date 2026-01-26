{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config.themeSwitcher;
  themeSwitcherScript = pkgs.writeShellScriptBin "theme-switcher" ''
    #!/usr/bin/env bash

    set -euo pipefail

    # Ensure inputs.self is available if it's used in the flake context for 'nix build'
    FLAKE_PATH="${toString inputs.self}" # Dynamically get the flake path

    THEME="$1"
    
    # If no theme provided, open wofi menu
    if [[ -z "$THEME" ]]; then
        THEME=$(echo -e "dark\nlight" | ${pkgs.wofi}/bin/wofi --dmenu --prompt "Choose Theme" --width 300 --height 200 --cache-file /dev/null)
        
        if [[ -z "$THEME" ]]; then
            echo "No theme selected."
            exit 1
        fi
    fi

    # Validate theme
    if [[ "$THEME" != "dark" && "$THEME" != "light" ]]; then
        echo "Invalid theme: $THEME"
        echo "Available themes: dark, light"
        exit 1
    fi

    # Resolve the Nix store path for the chosen theme's configurations
    THEME_CONFIG_PATH=$(nix build --no-link --print-out-paths "${FLAKE_PATH}#packages.$(nix-instantiate --eval -E 'builtins.currentSystem' --json | tr -d '"').${THEME}ThemeConfigs")

    if [[ -z "$THEME_CONFIG_PATH" ]]; then
        echo "Error: Could not find theme configuration for '$THEME'."
        exit 1
    fi

    echo "Activating theme: $THEME from $THEME_CONFIG_PATH"

    # --- 1. Clean up previous theme artifacts (IMPORTANT) ---
    # Remove old symlinks/directories to ensure a clean switch
    rm -rf "$HOME/.themes/adw-gtk3"
    rm -rf "$HOME/.themes/adw-gtk3-dark"
    rm -rf "$HOME/.icons/hicolor" # Clean up specific icon cache if necessary
    rm -rf "$HOME/.local/share/color-schemes/*" # Clean up previous color schemes
    rm -rf "$HOME/.local/share/plasma/look-and-feel/stylix" # Clean up previous plasma look and feel

    # --- 2. Create new symlinks based on generated theme configuration ---

    # GTK Themes
    ln -sf "${THEME_CONFIG_PATH}/share/themes/adw-gtk3" "$HOME/.themes/adw-gtk3"
    ln -sf "${THEME_CONFIG_PATH}/share/themes/adw-gtk3-dark" "$HOME/.themes/adw-gtk3-dark"

    # Icons
    ln -sf "${THEME_CONFIG_PATH}/share/icons/hicolor" "$HOME/.icons/hicolor"

    # Color Schemes
    mkdir -p "$HOME/.local/share/color-schemes"
    cp "${THEME_CONFIG_PATH}/share/color-schemes/"* "$HOME/.local/share/color-schemes/" # Copy all color schemes

    # Plasma Look and Feel
    mkdir -p "$HOME/.local/share/plasma/look-and-feel"
    ln -sf "${THEME_CONFIG_PATH}/share/plasma/look-and-feel/stylix" "$HOME/.local/share/plasma/look-and-feel/stylix"

    # --- 3. Apply theme settings using command-line tools ---

    # Wallpaper paths
    WALLPAPER_DARK="${./../common/assets/kanagawa.png}"
    WALLPAPER_LIGHT="${./../common/assets/BLACK_VII_desktop.jpg}"

    # GTK Theme & Wallpaper
    if [ "$THEME" == "dark" ]; then
        gsettings set org.gnome.desktop.interface gtk-theme "Adw-gtk3-dark"
        gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" # For libadwaita/GTK4 apps
        
        # Switch Wallpaper
        pkill swaybg || true
        ${pkgs.swaybg}/bin/swaybg -i "$WALLPAPER_DARK" &

    elif [ "$THEME" == "light" ]; then
        gsettings set org.gnome.desktop.interface gtk-theme "Adw-gtk3"
        gsettings set org.gnome.desktop.interface color-scheme "prefer-light" # For libadwaita/GTK4 apps

        # Switch Wallpaper
        pkill swaybg || true
        ${pkgs.swaybg}/bin/swaybg -i "$WALLPAPER_LIGHT" &
    fi
    # Optional: Set icon theme if Stylix manages a specific one
    # gsettings set org.gnome.desktop.interface icon-theme "hicolor" # Assuming hicolor is the generated icon theme

    # Qt (Kvantum)
    # Stylix usually sets QT_QPA_PLATFORMTHEME in home-manager activation
    # For runtime switching, we might need to export it and possibly restart applications
    export QT_QPA_PLATFORMTHEME="qt5ct" # Or qt6ct depending on setup
    # Optional: If Kvantum theme is also generated, set it here.
    # For example, `kvantummanager --set KvAdwaitaDark`

    # Xresources - Skipped for now, as not directly generated statically by Stylix for extraction
    # Alacritty - Skipped for now, as not directly generated statically by Stylix for extraction

    echo "Theme '$THEME' applied. You may need to restart some applications (e.g., Alacritty, terminal emulators) for full effect."
    echo "For Qt applications, you might need to ensure QT_QPA_PLATFORMTHEME is set in your session."
  '';
in
{
  options.themeSwitcher = {
    enable = lib.mkEnableOption "Enable theme switching functionality.";

    defaultTheme = lib.mkOption {
      type = lib.types.enum [
        "dark"
        "light"
      ];
      default = "dark";
      description = "The default theme to apply on login.";
    };

    hotkeySwitching.enable = lib.mkEnableOption "Enable hotkey-based theme switching.";
    hotkeySwitching.command = lib.mkOption {
      type = lib.types.str;
      default = "${themeSwitcherScript}/bin/theme-switcher";
      description = "The command to execute for switching themes via hotkey. It should accept 'dark' or 'light' as arguments.";
    };

    timeBasedSwitching.enable = lib.mkEnableOption "Enable time-based theme switching.";
    timeBasedSwitching.lightTime = lib.mkOption {
      type = lib.types.str; # e.g., "08:00"
      default = "08:00";
      description = "The time to switch to the light theme (HH:MM).";
    };
    timeBasedSwitching.darkTime = lib.mkOption {
      type = lib.types.str; # e.g., "20:00"
      default = "20:00";
      description = "The time to switch to the dark theme (HH:MM).";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ themeSwitcherScript ];

    # Set initial theme on login
    home.activation.setInitialTheme = lib.mkIf (cfg.defaultTheme != null) {
      after = [ "writeBoundary" ];
      # Ensure theme-switcher is available in PATH for activation
      # Note: We use `pkgs.writeShellScript` to create a script that calls our themeSwitcherScript
      # with the correct PATH, as `home.activation` runs before user PATH is fully set.
      text = ''
        export PATH="${pkgs.lib.makeBinPath config.home.packages}:$PATH"
        ${themeSwitcherScript}/bin/theme-switcher "${cfg.defaultTheme}"
      '';
    };

    # Configure time-based switching using systemd user timers
    systemd.user.services.theme-switcher-light = lib.mkIf cfg.timeBasedSwitching.enable {
      Unit = {
        Description = "Switch to light theme";
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${themeSwitcherScript}/bin/theme-switcher light";
        Type = "oneshot";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    systemd.user.timers.theme-switcher-light = lib.mkIf cfg.timeBasedSwitching.enable {
      Unit = {
        Description = "Timer for light theme switch";
      };
      Timer = {
        OnCalendar = "*-*-* ${cfg.timeBasedSwitching.lightTime}:00";
        Persistent = true;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };

    systemd.user.services.theme-switcher-dark = lib.mkIf cfg.timeBasedSwitching.enable {
      Unit = {
        Description = "Switch to dark theme";
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${themeSwitcherScript}/bin/theme-switcher dark";
        Type = "oneshot";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    systemd.user.timers.theme-switcher-dark = lib.mkIf cfg.timeBasedSwitching.enable {
      Unit = {
        Description = "Timer for dark theme switch";
      };
      Timer = {
        OnCalendar = "*-*-* ${cfg.timeBasedSwitching.darkTime}:00";
        Persistent = true;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };

    # TODO: Hotkey configuration (e.g., sxhkd) - This would depend on user's existing setup
    # and might need to be a separate module or option here.
    # For now, users can manually bind `themeSwitcherScript light` and `themeSwitcherScript dark`.
  };
}

# Backup of Hyprland configuration from omarchy-nix. Enable with programs.hyprland-backup.enable = true
#
# This is a home-manager module that consolidates all Hyprland settings from omarchy-nix
# including: bindings, look-and-feel, envs, input, windows, autostart, hyprlock,
# hypridle, hyprpaper, and wofi scripts.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.hyprland-backup;

  wallpaperPath = builtins.toString ../../modules/theming/assets/BLACK_VII_desktop.jpg;

  # ── wofi scripts ────────────────────────────────────────────────────
  BOOKMARKS = "~/.bookmarks";

  wofi-bookmark = pkgs.writeShellScriptBin "wofi-bookmark" ''
    chosen=`cat ${BOOKMARKS} | wofi --show=dmenu | awk '{ print $2 }'`

    if [[ ! $chosen ]]; then
      return
    fi

    exec "$1" $chosen
  '';

  wofi-search-browser = pkgs.writeShellScriptBin "wofi-search-browser" ''
    # prompt for search query
    query=$(wofi --dmenu --prompt "brave search:")

    # exit if empty
    [ -z "$query" ] && exit

    # url encode function (requires jq)
    urlencode() {
        printf '%s' "$1" | jq -sRr @uri
    }

    if [[ $query == !* ]]; then
        prefix="''${query:1:1}"
        rest="''${query:2}"
        rest_trimmed="$(echo "$rest" | sed 's/^ *//')"
        case "$prefix" in
            g) search_url="https://www.google.com/search?q=$(urlencode "$rest_trimmed")" ;;
            b) search_url="https://search.brave.com/search?q=$(urlencode "$rest_trimmed")" ;;
            a) search_url="https://chat.openai.com/?q=$(urlencode "$rest_trimmed")" ;;
            n) search_url="https://search.nixos.org/packages?query=$(urlencode "$rest_trimmed")" ;;
            *) search_url="https://search.brave.com/search?q=$(urlencode "$query")" ;;
        esac
    else
        search_url="https://search.brave.com/search?q=$(urlencode "$query")"
    fi

    # check if brave is running
    if pgrep -x brave >/dev/null; then
        brave --new-tab "$search_url"
    else
        brave "$search_url" &
    fi
  '';
in
{
  # ── option ──────────────────────────────────────────────────────────
  options.programs.hyprland-backup.enable = lib.mkEnableOption "consolidated Hyprland backup configuration from omarchy-nix";

  # ── config ──────────────────────────────────────────────────────────
  config = lib.mkIf cfg.enable {

    # Make wofi scripts available on PATH
    home.packages = [
      wofi-bookmark
      wofi-search-browser
    ];

    # ── polkit agent ────────────────────────────────────────────────
    services.hyprpolkitagent.enable = true;

    # ── Hyprland window manager ─────────────────────────────────────
    wayland.windowManager.hyprland = {
      enable = true;
      package = pkgs.hyprland;

      settings = {
        # ── default applications (configuration.nix) ────────────────
        "$terminal" = lib.mkDefault "alacritty";
        "$fileManager" = lib.mkDefault "nautilus --new-window";
        "$browser" = lib.mkDefault "brave --new-window --ozone-platform=wayland";
        "$music" = lib.mkDefault "spotify";
        "$passwordManager" = lib.mkDefault "1password";
        "$messenger" = lib.mkDefault "signal-desktop";
        "$webapp" = lib.mkDefault "$browser --app";
        "$email" = lib.mkDefault "thunderbird";

        # Monitor — override per-host as needed
        monitor = lib.mkDefault [ ",preferred,auto,auto" ];

        # ── environment variables (envs.nix) ────────────────────────
        env = [
          "GDK_SCALE,1"

          # Cursor
          "XCURSOR_SIZE,24"
          "HYPRCURSOR_SIZE,24"
          "XCURSOR_THEME,Adwaita"
          "HYPRCURSOR_THEME,Adwaita"

          # Wayland everywhere
          "GDK_BACKEND,wayland"
          "QT_QPA_PLATFORM,wayland"
          "QT_STYLE_OVERRIDE,kvantum"
          "SDL_VIDEODRIVER,wayland"
          "MOZ_ENABLE_WAYLAND,1"
          "ELECTRON_OZONE_PLATFORM_HINT,wayland"
          "OZONE_PLATFORM,wayland"

          # Chromium flags
          ''CHROMIUM_FLAGS,"--enable-features=UseOzonePlatform --ozone-platform=wayland --gtk-version=4"''

          # Desktop file discovery for wofi
          "XDG_DATA_DIRS,$XDG_DATA_DIRS:$HOME/.nix-profile/share:/nix/var/nix/profiles/default/share"

          # XCompose
          "XCOMPOSEFILE,~/.XCompose"
          "EDITOR,nvim"

          # GTK dark theme
          "GTK_THEME,Adwaita:dark"
        ];

        xwayland = {
          force_zero_scaling = true;
        };

        ecosystem = {
          no_update_news = true;
        };

        # ── input (input.nix) ───────────────────────────────────────
        input = lib.mkDefault {
          kb_layout = "us";
          kb_options = "caps:swapescape";
          follow_mouse = 1;
          sensitivity = 0;
          touchpad = {
            natural_scroll = false;
          };
        };

        # ── look and feel (looknfeel.nix) ───────────────────────────
        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
          # Border colors are handled by stylix
          resize_on_border = false;
          allow_tearing = false;
          layout = "scrolling";
        };

        plugin = {
          hyprscrolling = {
            column_width = 0.5;
            fullscreen_on_one_column = false;
          };
          hyprexpo = {
            columns = 3;
            gap_size = 8;
            bg_col = "rgb(111111)";
            workspace_method = "center current";
          };
        };

        decoration = {
          rounding = 4;

          shadow = {
            enabled = false;
            range = 30;
            render_power = 3;
            ignore_window = true;
          };

          blur = {
            enabled = true;
            size = 5;
            passes = 2;
            vibrancy = 0.1696;
          };
        };

        animations = {
          enabled = true;

          bezier = [
            "easeOutQuint,0.23,1,0.32,1"
            "easeInOutCubic,0.65,0.05,0.36,1"
            "linear,0,0,1,1"
            "almostLinear,0.5,0.5,0.75,1.0"
            "quick,0.15,0,0.1,1"
            "myBezier, 0.05, 0.9, 0.1, 1.05"
          ];

          animation = [
            "global, 1, 10, default"
            "border, 1, 5.39, easeOutQuint"
            "windows, 1, 7, myBezier"
            "windowsOut, 1, 7, default, popin 80%"
            "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
            "fadeIn, 1, 1.73, almostLinear"
            "fadeOut, 1, 1.46, almostLinear"
            "fade, 1, 3.03, quick"
            "layers, 1, 3.81, easeOutQuint"
            "layersIn, 1, 4, easeOutQuint, fade"
            "layersOut, 1, 1.5, linear, fade"
            "fadeLayersIn, 1, 1.79, almostLinear"
            "fadeLayersOut, 1, 1.39, almostLinear"
            "workspaces, 0, 0, ease"
          ];
        };

        dwindle = {
          pseudotile = true;
          preserve_split = true;
          force_split = 2;
        };

        master = {
          new_status = "master";
        };

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
        };

        # ── window rules (windows.nix) ──────────────────────────────
        windowrule = [
          "suppressevent maximize, class:.*"
          "tile, class:^(chromium)$"
          "float, class:^(org.pulseaudio.pavucontrol|blueman-manager)$"
          "float, class:^(steam)$"
          "fullscreen, class:^(com.libretro.RetroArch)$"

          # Opacity
          "opacity 0.97 0.9, class:.*"
          "opacity 1 1, class:^(chromium|google-chrome|google-chrome-unstable)$, title:.*Youtube.*"
          "opacity 1 0.97, class:^(chromium|google-chrome|google-chrome-unstable)$"
          "opacity 0.97 0.9, initialClass:^(chrome-.*-Default)$ # web apps"
          "opacity 1 1, initialClass:^(chrome-youtube.*-Default)$ # Youtube"
          "opacity 1 1, class:^(zoom|vlc|org.kde.kdenlive|com.obsproject.Studio)$"
          "opacity 1 1, class:^(com.libretro.RetroArch|steam)$"

          # XWayland drag fix
          "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"

          # Clipse clipboard manager
          "float, class:(clipse)"
          "size 622 652, class:(clipse)"
          "stayfocused, class:(clipse)"
        ];

        layerrule = [
          "blur,wofi"
          "blur,waybar"
        ];

        # ── autostart (autostart.nix) ───────────────────────────────
        exec-once = [
          "hyprsunset"
          "systemctl --user start hyprpolkitagent"
          "wl-clip-persist --clipboard regular & clipse -listen"
        ];

        exec = [
          "pkill -SIGUSR2 waybar || waybar"
        ];

        # ── keybindings (bindings.nix) ──────────────────────────────
        bind = [
          "SUPER, space, exec, wofi --show drun --sort-order=alphabetical"
          "SUPER SHIFT, SPACE, exec, pkill -SIGUSR1 waybar"

          "SUPER, W, killactive,"
          "SUPER, Backspace, killactive,"

          # Session
          "SUPER, ESCAPE, exec, hyprlock"
          "SUPER SHIFT, ESCAPE, exit,"
          "SUPER CTRL, ESCAPE, exec, reboot"
          "SUPER SHIFT CTRL, ESCAPE, exec, systemctl poweroff"

          # Tab groups
          "SUPER, G, togglegroup"
          "SUPER, TAB, changegroupactive, f"
          "SUPER SHIFT, TAB, changegroupactive, b"
          "SUPER SHIFT, G, moveoutofgroup"

          # Tiling
          "SUPER SHIFT, N, togglesplit, # dwindle"
          "SUPER, P, pseudo, # dwindle"
          "SUPER, V, togglefloating,"
          "SUPER, C, exec, hyprctl dispatch togglefloating; hyprctl dispatch centerwindow"
          "SUPER SHIFT, return, fullscreen,"

          # Focus (arrows)
          "SUPER, left, movefocus, l"
          "SUPER, right, movefocus, r"
          "SUPER, up, movefocus, u"
          "SUPER, down, movefocus, d"

          # Focus (vim)
          "SUPER, L, movefocus, r"
          "SUPER, H, movefocus, l"
          "SUPER, K, movefocus, u"
          "SUPER, J, movefocus, d"

          # Swap window (vim)
          "SUPER SHIFT, L, swapwindow, l"
          "SUPER SHIFT, H, swapwindow, r"
          "SUPER SHIFT, K, swapwindow, u"
          "SUPER SHIFT, J, swapwindow, d"

          # Workspaces
          "SUPER, 1, workspace, 1"
          "SUPER, 2, workspace, 2"
          "SUPER, 3, workspace, 3"
          "SUPER, 4, workspace, 4"
          "SUPER, 5, workspace, 5"
          "SUPER, 6, workspace, 6"
          "SUPER, 7, workspace, 7"
          "SUPER, 8, workspace, 8"
          "SUPER, 9, workspace, 9"
          "SUPER, 0, workspace, 10"

          "SUPER, comma, workspace, -1"
          "SUPER, period, workspace, +1"

          # Move to workspace
          "SUPER SHIFT, 1, movetoworkspace, 1"
          "SUPER SHIFT, 2, movetoworkspace, 2"
          "SUPER SHIFT, 3, movetoworkspace, 3"
          "SUPER SHIFT, 4, movetoworkspace, 4"
          "SUPER SHIFT, 5, movetoworkspace, 5"
          "SUPER SHIFT, 6, movetoworkspace, 6"
          "SUPER SHIFT, 7, movetoworkspace, 7"
          "SUPER SHIFT, 8, movetoworkspace, 8"
          "SUPER SHIFT, 9, movetoworkspace, 9"
          "SUPER SHIFT, 0, movetoworkspace, 10"

          # Swap window (arrows)
          "SUPER SHIFT, left, swapwindow, l"
          "SUPER SHIFT, right, swapwindow, r"
          "SUPER SHIFT, up, swapwindow, u"
          "SUPER SHIFT, down, swapwindow, d"

          # Resize
          "SUPER, minus, resizeactive, -100 0"
          "SUPER, equal, resizeactive, 100 0"
          "SUPER SHIFT, minus, resizeactive, 0 -100"
          "SUPER SHIFT, equal, resizeactive, 0 100"

          # Scroll workspaces
          "SUPER, mouse_down, workspace, e+1"
          "SUPER, mouse_up, workspace, e-1"

          # Apple Display brightness
          "CTRL, F1, exec, ~/.local/share/omarchy/bin/apple-display-brightness -5000"
          "CTRL, F2, exec, ~/.local/share/omarchy/bin/apple-display-brightness +5000"
          "SHIFT CTRL, F2, exec, ~/.local/share/omarchy/bin/apple-display-brightness +60000"

          # Special workspace
          "SUPER, S, togglespecialworkspace, magic"
          "SUPER SHIFT, S, movetoworkspace, special:magic"

          # Screenshots
          ", PRINT, exec, hyprshot -m region"
          "SHIFT, PRINT, exec, hyprshot -m window"
          "CTRL, PRINT, exec, hyprshot -m output"

          # Color picker
          "SUPER, PRINT, exec, hyprpicker -a"

          # Clipse
          "SUPER CTRL, V, exec, ghostty --class clipse -e clipse"

          # Custom scripts
          "SUPER CTRL, B, exec, wofi-bookmark $browser"
          "SUPER, backslash, exec, wofi-search-browser"
        ];

        bindm = [
          "SUPER, mouse:272, movewindow"
          "SUPER, mouse:273, resizewindow"
        ];

        bindel = [
          ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
          ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          ",XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+"
          ",XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
        ];

        bindl = [
          ", XF86AudioNext, exec, playerctl next"
          ", XF86AudioPause, exec, playerctl play-pause"
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioPrev, exec, playerctl previous"
        ];
      }; # end settings
    }; # end wayland.windowManager.hyprland

    # ── hyprlock (hyprlock.nix) ─────────────────────────────────────
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          disable_loading_bar = true;
          no_fade_in = false;
        };
        auth = {
          fingerprint.enabled = true;
        };
        background = {
          monitor = "";
          path = wallpaperPath;
        };
        input-field = {
          monitor = "";
          size = "600, 100";
          position = "0, 0";
          halign = "center";
          valign = "center";
          outline_thickness = 4;
          font_family = "CaskaydiaMono Nerd Font";
          font_size = 32;
          placeholder_text = "  Enter Password 󰈷 ";
          fail_text = "Wrong";
          rounding = 0;
          shadow_passes = 0;
          fade_on_empty = false;
        };
        label = {
          monitor = "";
          text = "\$FPRINTPROMPT";
          text_align = "center";
          font_size = 24;
          font_family = "CaskaydiaMono Nerd Font";
          position = "0, -100";
          halign = "center";
          valign = "center";
        };
      };
    };

    # ── hypridle (hypridle.nix) ─────────────────────────────────────
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };
        listener = [
          {
            timeout = 300;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 330;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on && brightnessctl -r";
          }
        ];
      };
    };

    # ── hyprpaper (hyprpaper.nix) ──────────────────────────────────
    services.hyprpaper = {
      enable = true;
      settings = {
        preload = [
          wallpaperPath
        ];
        wallpaper = [
          ",${wallpaperPath}"
        ];
      };
    };

  }; # end config
}

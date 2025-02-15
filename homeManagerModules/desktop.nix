{ config, pkgs, ... }:

{
    # waybar
    programs.waybar = {
        enable = true;

        style = ''
          ${builtins.readFile "${pkgs.waybar}/etc/xdg/waybar/style.css"}

          window#waybar {
            background: transparent;
            border-bottom: none;
          }
        '';

        settings = [{
        height = 30;
        layer = "top";
        position = "bottom";
        tray = { spacing = 10; };
        modules-center = [];
        modules-left = ["hyprland/workspaces"];
        modules-right = [
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "temperature"
          "bluetooth"
        ]
        ++ [
          "clock"
          "tray"
        ];
        "hyprland/workspaces" = {
          "format" = "<sub>{icon}</sub>\n{windows}";
          "format-window-separator" = "\n";
          "window-rewrite-default"= "";
          "window-rewrite" = {
              "title<.*youtube.*>" = ""; # Windows whose titles contain "youtube"
              "class<firefox>" = ""; # Windows whose classes are "firefox"
              "brave" = ""; # Windows whose classes are "firefox"
              "class<firefox> title<.*github.*>" = ""; # Windows whose class is "firefox" and title contains "github". Note that "class" always comes first.
              "alacritty" = ""; # Windows that contain "foot" in either class or title. For optimization reasons, it will only match against a title if at least one other window explicitly matches against a title.
              # "kitty" = "󰨞";
              "kitty" = ""; # Windows that contain "foot" in either class or title. For optimization reasons, it will only match against a title if at least one other window explicitly matches against a title.
              "wezterm" = ""; # Windows that contain "foot" in either class or title. For optimization reasons, it will only match against a title if at least one other window explicitly matches against a title.
          };
        };
        battery = {
          format = "{capacity}% {icon}";
          format-alt = "{time} {icon}";
          format-charging = "{capacity}% ";
          format-icons = [ "" "" "" "" "" ];
          format-plugged = "{capacity}% ";
          states = {
            critical = 15;
            warning = 30;
          };
        };
        clock = {
          format-alt = "{:%Y-%m-%d}";
          tooltip-format = "{:%Y-%m-%d | %H:%M}";
        };
        cpu = {
          format = "{usage}% ";
          tooltip = false;
        };
        memory = { format = "{}% "; };
        network = {
          interval = 1;
          format-alt = "{ifname}: {ipaddr}/{cidr}";
          format-disconnected = "Disconnected ⚠";
          format-ethernet = "{ifname}: {ipaddr}/{cidr}   up: {bandwidthUpBits} down: {bandwidthDownBits}";
          format-linked = "{ifname} (No IP) ";
          format-wifi = "{essid} ({signalStrength}%) ";
        };
        pulseaudio = {
          format = "{volume}% {icon} {format_source}";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-icons = {
            car = "";
            default = [ "" "" "" ];
            handsfree = "";
            headphones = "";
            headset = "";
            phone = "";
            portable = "";
          };
          format-muted = " {format_source}";
          format-source = "{volume}% ";
          format-source-muted = "";
          on-click = "pavucontrol";
        };
        # "bluetooth" = {
        #     controller = "controller1";
        #     format = "󰂯 {status}";
        #     format-on = "󰂯";
        #     format-off = "󰂲";
        #     format-disabled = "";
        #     format-connected = "󰂱 {num_connections}";
        #     tooltip-format = "{controller_alias}\t{controller_address}";
        #     tooltip-format-connected = "{device_enumerate}";
        #     tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
        #     on-click = "blueman-manager";
        # };
        temperature = {
          critical-threshold = 80;
          format = "{temperatureC}°C {icon}";
          format-icons = [ "" "" "" ];
        };
      }];
    };

    # hyprlock
    programs.hyprlock = {
        enable = true;
        settings = {
            background = {
                monitor = "";
                path = "/home/salhashemi2/Pictures/wallpapers/dark_moon.png";
                blur_passes = 2;
                contrast = 1;
                vibrancy = 0.2;
            };      
            # GENERAL
            general = {
                no_fade_in = true;
                no_fade_out = true;
                hide_cursor = false;
                grace = 0;
                disable_loading_bar = true;
            };
            # INPUT FIELD
            input-field = {
                monitor = "";
                size = "250, 60";
                outline_thickness = 2;
                dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
                dots_spacing = 0.35; # Scale of dots' absolute size, 0.0 - 1.0
                dots_center = true;
                outer_color = "rgba(0, 0, 0, 0)";
                inner_color = "rgba(0, 0, 0, 0.2)";
                font_color = "$foreground";
                fade_on_empty = false;
                rounding = -1;
                check_color = "rgb(204, 136, 34)";
                placeholder_text = "<i><span foreground='##cdd6f4'>Input Password...</span></i>";
                hide_input = false;
                position = "0, -200";
                halign = "center";
                valign = "center";
            };

            # DATE
            label = [
                {
                  monitor = "";
                  text = ''
                    cmd[update:1000] echo "$(date +"%A, %B %d")"
                  '';
                  color = "rgba(242, 243, 244, 0.75)";
                  font_size = 22;
                  # font_family = "JetBrains Mono";
                  position = "0, 300";
                  halign = "center";
                  valign = "center";
                }

                # TIME
                {
                  monitor = "";
                  text = ''
                    cmd[update:1000] echo "$(date +"%-I:%M")"
                  '';
                  color = "rgba(242, 243, 244, 0.75)";
                  font_size = 95;
                  # font_family = JetBrains Mono Extrabold;
                  position = "0, 200";
                  halign = "center";
                  valign = "center";
                }

            ];

            # Profile Picture
            image = {
                monitor = "";
                path = "/home/salhashemi2/Pictures/wallpapers/green_mountains.png";
                size = 100;
                border_size = 2;
                border_color = "$foreground";
                position = "0, -100";
                halign = "center";
                valign = "center";
            };
        };
    };

    # hyprland
    wayland.windowManager.hyprland.enable = true;
    wayland.windowManager.hyprland.settings = {
        # enable = true;
        debug = {
            damage_tracking = 0;
        };
        monitor = [
            ",preferred,auto,auto"
             "Unknown-1,disable"
        ];

        env = [
            "XCURSOR_SIZE,24"
            "HYPRCURSOR_SIZE,24"
            # https://wiki.hyprland.org/Nvidia/#environment-variables
            "LIBVA_DRIVER_NAME,nvidia"
            "XDG_SESSION_TYPE,wayland"
            "GBM_BACKEND,nvidia-drm"
            # https://wiki.hyprland.org/Nvidia/#va-api-hardware-video-acceleration
            "NVD_BACKEND,direct" 
            # https://wiki.hyprland.org/Nvidia/#flickering-in-electron--cef-apps
            "ELECTRON_OZONE_PLATFORM_HINT,x11"
        ];

        # dwindle = {
        #   pseudotile = true;
        #   preserve_split = true;
        # };

        cursor = {
            no_hardware_cursors = true;
        };
        "$mod" = "SUPER";
        "$term" = "alacritty";
        exec-once = [
            "waybar"
            "hyprpaper"
        ];
        bindm = [
            "ALT,mouse:272,movewindow"
            "ALT,mouse:273,resizewindow"
        ];
        bind = [
            "$mod, B, exec, brave --ozone-platform-hint=x11"
            "$mod, T, exec, $term"
            # "$mod, R, exec, tofi-run | xargs -I {} sh -c '{}'"
            "$mod, R, exec, wofi --show drun"
            "$mod, C, killactive"
            "$mod, M, exit"
            "$mod, V, togglefloating"
            "$mod, J, togglesplit"
            "$mod, S, togglespecialworkspace, magic"
            "$mod, F, fullscreen"
            "$mod SHIFT, S, movetoworkspace, special:magic"
            "$mod, left, movefocus, l"
            "$mod, h, movefocus, l"
            "$mod, right, movefocus, r"
            "$mod, l, movefocus, r"
            "$mod, up, movefocus, u"
            "$mod, k, movefocus, u"
            "$mod, down, movefocus, d"
            "$mod, j, movefocus, d"
            "$mod, p, layoutmsg, rollprev"
            "$mod, n, layoutmsg, rollnext"
            "$mod, n, layoutmsg, swapwithmaster master"
            "$mod SHIFT, H, movewindow, l"
            "$mod SHIFT, L, movewindow, r"
            "$mod SHIFT, K, movewindow, u"
            "$mod SHIFT, J, movewindow, d"

            "$mod SHIFT, right, resizeactive, 10 0"
            "$mod SHIFT, left, resizeactive, -10 0"
            "$mod SHIFT, up, resizeactive, 0 -10"
            "$mod SHIFT, down, resizeactive, 0 10"

            # volume control
            ",XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +10%"
            ",XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -10%"
            ",XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"
            ",XF86AudioMicMute, exec, pactl set-source-mute @DEFAULT_SINK@ toggle"

            # lock screen
            "$mod SHIFT, P, exec, hyprlock"
        ]
        ++ (
            # workspaces
            # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
            builtins.concatLists (builtins.genList (
                x: let
                  ws = let
                    c = (x + 1) / 10;
                  in
                    builtins.toString (x + 1 - (c * 10));
                in [
                  "$mod, ${ws}, workspace, ${toString (x + 1)}"
                  "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
                ]
              )
              10)
          );
    
        general = { 
            gaps_in = 5;
            gaps_out = 20;
    
            border_size = 2;
    
            # https://wiki.hyprland.org/Configuring/Variables/#variable-types for info about colors
            "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
            "col.inactive_border" = "rgba(595959aa)";
    
            # Set to true enable resizing windows by clicking and dragging on borders and gaps
            resize_on_border = false;
    
            # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
            allow_tearing = false;
    
            layout = "dwindle";
        };

        decoration = {
            rounding = 20;
            inactive_opacity = 0.95;
        };

        input = {
            kb_options = "caps:swapescape";
        };
    
        animations = {
            enabled = true;
    
            # Default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more
    
            bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
    
            animation = [
                "windows, 1, 7, myBezier"
                "windowsOut, 1, 7, default, popin 80%"
                "border, 1, 10, default"
                "borderangle, 1, 8, default"
                "fade, 1, 7, default"
                "workspaces, 1, 6, default, slidefadevert 20%"
            ];
        };
    
    };


}

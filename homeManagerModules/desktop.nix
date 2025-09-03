{ config, pkgs, ... }:

{
  # waybar
  programs.waybar = {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
    });
    settings.mainBar = {
      position = "top";
      layer = "top";
      height = 35;
      margin-top = 0;
      margin-bottom = 0;
      margin-left = 0;
      margin-right = 0;
      modules-left = [
        "custom/launcher"
        "custom/playerctl#backward"
        "custom/playerctl#play"
        "custom/playerctl#foward"
        "custom/playerlabel"
      ];
      modules-center = [
        "cava#left"
        "hyprland/workspaces"
        "cava#right"
      ];
      modules-right = [
        "tray"
        "battery"
        "pulseaudio"
        "network"
        "clock"
      ];
      clock = {
        format = " {:%a, %d %b, %I:%M %p}";
        tooltip = "true";
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        format-alt = " {:%d/%m}";
      };
      "wlr/workspaces" = {
        active-only = false;
        all-outputs = false;
        disable-scroll = false;
        on-scroll-up = "hyprctl dispatch workspace e-1";
        on-scroll-down = "hyprctl dispatch workspace e+1";
        format = "{name}";
        on-click = "activate";
        format-icons = {
          urgent = "";
          active = "";
          default = "";
          sort-by-number = true;
        };
      };
      "cava#left" = {
        framerate = 60;
        autosens = 1;
        bars = 18;
        lower_cutoff_freq = 50;
        higher_cutoff_freq = 10000;
        method = "pipewire";
        source = "auto";
        stereo = true;
        reverse = false;
        bar_delimiter = 0;
        monstercat = false;
        waves = false;
        input_delay = 2;
      };
      "cava#right" = {
        framerate = 60;
        autosens = 1;
        bars = 18;
        lower_cutoff_freq = 50;
        higher_cutoff_freq = 10000;
        method = "pipewire";
        source = "auto";
        stereo = true;
        reverse = false;
        bar_delimiter = 0;
        monstercat = false;
        waves = false;
        input_delay = 2;
      };
      "custom/playerctl#backward" = {
        format = "󰙣 ";
        on-click = "playerctl previous";
        on-scroll-up = "playerctl volume .05+";
        on-scroll-down = "playerctl volume .05-";
      };
      "custom/playerctl#play" = {
        format = "{icon}";
        return-type = "json";
        exec = "playerctl -a metadata --format '{\"text\": \"{{artist}} - {{markup_escape(title)}}\", \"tooltip\": \"{{playerName}} : {{markup_escape(title)}}\", \"alt\": \"{{status}}\", \"class\": \"{{status}}\"}' -F";
        on-click = "playerctl play-pause";
        on-scroll-up = "playerctl volume .05+";
        on-scroll-down = "playerctl volume .05-";
        format-icons = {
          Playing = "<span>󰏥 </span>";
          Paused = "<span> </span>";
          Stopped = "<span> </span>";
        };
      };
      "custom/playerctl#foward" = {
        format = "󰙡 ";
        on-click = "playerctl next";
        on-scroll-up = "playerctl volume .05+";
        on-scroll-down = "playerctl volume .05-";
      };
      "custom/playerlabel" = {
        format = "<span>󰎈 {} 󰎈</span>";
        return-type = "json";
        max-length = 40;
        exec = "playerctl -a metadata --format '{\"text\": \"{{artist}} - {{markup_escape(title)}}\", \"tooltip\": \"{{playerName}} : {{markup_escape(title)}}\", \"alt\": \"{{status}}\", \"class\": \"{{status}}\"}' -F";
        on-click = "";
      };
      battery = {
        states = {
          good = 95;
          warning = 30;
          critical = 15;
        };
        format = "{icon}  {capacity}%";
        format-charging = "  {capacity}%";
        format-plugged = " {capacity}% ";
        format-alt = "{icon} {time}";
        format-icons = [
          ""
          ""
          ""
          ""
          ""
        ];
      };

      memory = {
        format = "󰍛 {}%";
        format-alt = "󰍛 {used}/{total} GiB";
        interval = 5;
      };
      cpu = {
        format = "󰻠 {usage}%";
        format-alt = "󰻠 {avg_frequency} GHz";
        interval = 5;
      };
      network = {
        format-wifi = "  {signalStrength}%";
        format-ethernet = "󰈀 100% ";
        tooltip-format = "Connected to {essid} {ifname} via {gwaddr}";
        format-linked = "{ifname} (No IP)";
        format-disconnected = "󰖪 0% ";
      };
      tray = {
        icon-size = 20;
        spacing = 8;
      };
      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "󰝟";
        format-icons = {
          default = [
            "󰕿"
            "󰖀"
            "󰕾"
          ];
        };
        # on-scroll-up= "bash ~/.scripts/volume up";
        # on-scroll-down= "bash ~/.scripts/volume down";
        scroll-step = 5;
        on-click = "pavucontrol";
      };
      "custom/randwall" = {
        format = "󰏘";
        # on-click= "bash $HOME/.config/hypr/randwall.sh";
        # on-click-right= "bash $HOME/.config/hypr/wall.sh";
      };
      "custom/launcher" = {
        format = "";
        # on-click= "bash $HOME/.config/rofi/launcher.sh";
        # on-click-right= "bash $HOME/.config/rofi/run.sh";
        tooltip = "false";
      };
    };
    style = ''
      * {
          border: none;
          border-radius: 0px;
          font-family: RobotoMono Nerd Font;
          font-size: 14px;
          min-height: 0;
      }

      window#waybar {
          background: rgba(17,17,27,1);
      }

      #cava.left, #cava.right {
          background: #25253a;
          margin: 5px; 
          padding: 8px 16px;
          color: #cba6f7;
      }
      #cava.left {
          border-radius: 24px 10px 24px 10px;
      }
      #cava.right {
          border-radius: 10px 24px 10px 24px;
      }
      #workspaces {
          background: #25253a;
          margin: 5px 5px;
          padding: 8px 5px;
          border-radius: 16px;
          color: #cba6f7
      }
      #workspaces button {
          padding: 0px 5px;
          margin: 0px 3px;
          border-radius: 16px;
          color: transparent;
          background: rgba(17,17,27,1);
          transition: all 0.3s ease-in-out;
      }

      #workspaces button.active {
          background-color: #89b4fa;
          color: #11111B;
          border-radius: 16px;
          min-width: 50px;
          background-size: 400% 400%;
          transition: all 0.3s ease-in-out;
      }

      #workspaces button:hover {
          background-color: #f5f5f5;
          color: #11111B;
          border-radius: 16px;
          min-width: 50px;
          background-size: 400% 400%;
      }

      #tray, #pulseaudio, #network, #battery,
      #custom-playerctl.backward, #custom-playerctl.play, #custom-playerctl.foward{
          background: #25253a;
          font-weight: bold;
          margin: 5px 0px;
      }
      #tray, #pulseaudio, #network, #battery{
          color: #f5f5f5;
          border-radius: 10px 24px 10px 24px;
          padding: 0 20px;
          margin-left: 7px;
      }
      #clock {
          color: #f5f5f5;
          background: #25253a;
          border-radius: 0px 0px 0px 40px;
          padding: 10px 10px 15px 25px;
          margin-left: 7px;
          font-weight: bold;
          font-size: 16px;
      }
      #custom-launcher {
          color: #89b4fa;
          background: #25253a;
          border-radius: 0px 0px 40px 0px;
          margin: 0px;
          padding: 0px 35px 0px 15px;
          font-size: 28px;
      }

      #custom-playerctl.backward, #custom-playerctl.play, #custom-playerctl.foward {
          background: #25253a;
          font-size: 22px;
      }
      #custom-playerctl.backward:hover, #custom-playerctl.play:hover, #custom-playerctl.foward:hover{
          color: #f5f5f5;
      }
      #custom-playerctl.backward {
          color: #cba6f7;
          border-radius: 24px 0px 0px 10px;
          padding-left: 16px;
          margin-left: 7px;
      }
      #custom-playerctl.play {
          color: #89b4fa;
          padding: 0 5px;
      }
      #custom-playerctl.foward {
          color: #cba6f7;
          border-radius: 0px 10px 24px 0px;
          padding-right: 12px;
          margin-right: 7px
      }
      #custom-playerlabel {
          background: #25253a;
          color: #f5f5f5;
          padding: 0 20px;
          border-radius: 24px 10px 24px 10px;
          margin: 5px 0;
          font-weight: bold;
      }
      #window{
          background: #25253a;
          padding-left: 15px;
          padding-right: 15px;
          border-radius: 16px;
          margin-top: 5px;
          margin-bottom: 5px;
          font-weight: normal;
          font-style: normal;
      }
    '';
  };
  # programs.waybar = {
  #     enable = true;
  #
  #     style = ''
  #       ${builtins.readFile "${pkgs.waybar}/etc/xdg/waybar/style.css"}
  #
  #       window#waybar {
  #         background: transparent;
  #         border-bottom: none;
  #       }
  #     '';
  #
  #     settings = [{
  #     height = 30;
  #     layer = "top";
  #     position = "bottom";
  #     tray = { spacing = 10; };
  #     modules-center = [];
  #     modules-left = ["hyprland/workspaces"];
  #     modules-right = [
  #       "pulseaudio"
  #       "network"
  #       "cpu"
  #       "memory"
  #       "temperature"
  #       "bluetooth"
  #     ]
  #     ++ [
  #       "clock"
  #       "tray"
  #     ];
  #     "hyprland/workspaces" = {
  #       "format" = "<sub>{icon}</sub>\n{windows}";
  #       "format-window-separator" = "\n";
  #       "window-rewrite-default"= "";
  #       "window-rewrite" = {
  #           "title<.*youtube.*>" = ""; # Windows whose titles contain "youtube"
  #           "class<firefox>" = ""; # Windows whose classes are "firefox"
  #           "brave" = ""; # Windows whose classes are "firefox"
  #           "class<firefox> title<.*github.*>" = ""; # Windows whose class is "firefox" and title contains "github". Note that "class" always comes first.
  #           "alacritty" = ""; # Windows that contain "foot" in either class or title. For optimization reasons, it will only match against a title if at least one other window explicitly matches against a title.
  #           # "kitty" = "󰨞";
  #           "kitty" = ""; # Windows that contain "foot" in either class or title. For optimization reasons, it will only match against a title if at least one other window explicitly matches against a title.
  #           "wezterm" = ""; # Windows that contain "foot" in either class or title. For optimization reasons, it will only match against a title if at least one other window explicitly matches against a title.
  #       };
  #     };
  #     battery = {
  #       format = "{capacity}% {icon}";
  #       format-alt = "{time} {icon}";
  #       format-charging = "{capacity}% ";
  #       format-icons = [ "" "" "" "" "" ];
  #       format-plugged = "{capacity}% ";
  #       states = {
  #         critical = 15;
  #         warning = 30;
  #       };
  #     };
  #     clock = {
  #       format-alt = "{:%Y-%m-%d}";
  #       tooltip-format = "{:%Y-%m-%d | %H:%M}";
  #     };
  #     cpu = {
  #       format = "{usage}% ";
  #       tooltip = false;
  #     };
  #     memory = { format = "{}% "; };
  #     network = {
  #       interval = 1;
  #       format-alt = "{ifname}: {ipaddr}/{cidr}";
  #       format-disconnected = "Disconnected ⚠";
  #       format-ethernet = "{ifname}: {ipaddr}/{cidr}   up: {bandwidthUpBits} down: {bandwidthDownBits}";
  #       format-linked = "{ifname} (No IP) ";
  #       format-wifi = "{essid} ({signalStrength}%) ";
  #     };
  #     pulseaudio = {
  #       format = "{volume}% {icon} {format_source}";
  #       format-bluetooth = "{volume}% {icon} {format_source}";
  #       format-bluetooth-muted = " {icon} {format_source}";
  #       format-icons = {
  #         car = "";
  #         default = [ "" "" "" ];
  #         handsfree = "";
  #         headphones = "";
  #         headset = "";
  #         phone = "";
  #         portable = "";
  #       };
  #       format-muted = " {format_source}";
  #       format-source = "{volume}% ";
  #       format-source-muted = "";
  #       on-click = "pavucontrol";
  #     };
  #     # "bluetooth" = {
  #     #     controller = "controller1";
  #     #     format = "󰂯 {status}";
  #     #     format-on = "󰂯";
  #     #     format-off = "󰂲";
  #     #     format-disabled = "";
  #     #     format-connected = "󰂱 {num_connections}";
  #     #     tooltip-format = "{controller_alias}\t{controller_address}";
  #     #     tooltip-format-connected = "{device_enumerate}";
  #     #     tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
  #     #     on-click = "blueman-manager";
  #     # };
  #     temperature = {
  #       critical-threshold = 80;
  #       format = "{temperatureC}°C {icon}";
  #       format-icons = [ "" "" "" ];
  #     };
  #   }];
  # };

  # hyprlock
  programs.hyprlock = {
    enable = true;
    settings = {
      background = {
        monitor = "";
        path = "/home/salhashemi2/Pictures/wallpapers/nix-wallpaper-nineish-solarized-dark.png";
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
        path = "/home/salhashemi2/Pictures/wallpapers/nix-wallpaper-nineish-solarized-dark.png";
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
      "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
    ];

    # dwindle = {
    #   pseudotile = true;
    #   preserve_split = true;
    # };

    xwayland.force_zero_scaling = true;

    plugin = {
      hyprbars = {
        bar_height = 20;
        bar_precedence_over_border = true;

        # order is right-to-left
        hyprbars-button = [
          # close
          "rgb(ffb4ab), 15, , hyprctl dispatch killactive"
          # maximize
          "rgb(b6c4ff), 15, , hyprctl dispatch fullscreen 1"
        ];
      };
    };

    cursor = {
      no_hardware_cursors = true;
    };
    "$mod" = "SUPER";
    "$term" = "alacritty";
    exec-once = [
      "waybar"
      "uwsm finalize"
      "hyprpaper"
      "hyprlock"
      "nextcloud"
    ];
    bindm = [
      "ALT,mouse:272,movewindow"
      "ALT,mouse:273,resizewindow"
    ];
    bind = [
      # "$mod, B, exec, brave --ozone-platform-hint=x11"
      "$mod, B, exec, zen"
      "$mod, T, exec, $term"
      "$mod, R, exec, tofi-run | xargs -I {} sh -c '{}'"
      # "$mod, D, exec, wofi --show drun"
      # "$mod, R, exec, wofi --show run"
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
      builtins.concatLists (
        builtins.genList (
          x:
          let
            ws =
              let
                c = (x + 1) / 10;
              in
              builtins.toString (x + 1 - (c * 10));
          in
          [
            "$mod, ${ws}, workspace, ${toString (x + 1)}"
            "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
          ]
        ) 10
      )
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

  # hyprpaper
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [ "/home/salhashemi2/Pictures/wallpapers/nix-wallpaper-nineish-solarized-dark.png" ];
      wallpaper = [
        "/home/salhashemi2/Pictures/wallpapers/nix-wallpaper-nineish-solarized-dark.png"
      ];
      ipc = "on";
    };
  };

}

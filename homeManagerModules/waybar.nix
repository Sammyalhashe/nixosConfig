{
  config,
  lib,
  pkgs,
  ...
}:

let
  betterTransition = "all 0.3s cubic-bezier(.55,-0.68,.48,1.682)";
in
{
  # Disable omarchy-nix waybar config files to avoid conflicts
  home.file.".config/waybar/" = {
    enable = lib.mkForce false;
  };
  home.file.".config/waybar/theme.css" = {
    enable = lib.mkForce false;
  };

  # Prevent Hyprland from starting waybar manually (conflicts with systemd)
  wayland.windowManager.hyprland.settings.exec = lib.mkForce [ ];

  home.packages = with pkgs; [
    wlogout
  ];

  programs.waybar = {
    enable = lib.mkForce true;
    systemd.enable = true;
    package = pkgs.waybar;
    settings = lib.mkForce {
      mainBar = {
        layer = "top";
        position = "top";
        height = 36;
        margin-top = 6;
        margin-left = 10;
        margin-right = 10;
        spacing = 8;

        modules-left = [
          "custom/launcher"
          "ext/workspaces"
          "hyprland/workspaces"
          "wlr/workspaces" # Fallback
          "custom/media"
        ];

        modules-center = [
          "clock"
        ];

        modules-right = [
          "custom/mangolayout"
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "battery"
          "tray"
          "custom/power"
        ];

        # Modules configuration
        "custom/mangolayout" = {
          exec = "mmsg -g -l | awk '{print $NF}' | sed 's/tile/Tiling/;s/scroller/Scroller/;s/monocle/Monocle/;s/grid/Grid/;s/deck/Deck/;s/center_tile/Center Tile/;s/right_tile/Right Tile/;s/vertical_tile/Vert Tile/;s/vertical_scroller/Vert Scroll/;s/vertical_grid/Vert Grid/;s/vertical_spiral/Vert Spiral/;s/vertical_deck/Vert Deck/;s/tgmix/TG Mix/'";
          interval = 1;
          format = "󰕰 {}";
          tooltip = false;
        };
        "custom/launcher" = {
          format = "";
          on-click = "wofi --show drun";
          tooltip = false;
        };

        "ext/workspaces" = {
          format = "{name}";
          on-click = "activate";
          all-outputs = true;
          ignore-hidden = false;
        };

        "hyprland/workspaces" = {
          active-only = false;
          all-outputs = true;
          format = "{name}";
          on-click = "activate";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            "10" = "10";
          };
          persistent-workspaces = {
            "1" = [ ];
            "2" = [ ];
            "3" = [ ];
            "4" = [ ];
            "5" = [ ];
            "6" = [ ];
            "7" = [ ];
            "8" = [ ];
            "9" = [ ];
            "10" = [ ];
          };
        };

        "wlr/workspaces" = {
          format = "{icon}";
          on-click = "activate";
          all-outputs = true;
          sort-by-number = true;
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            "10" = "10";
            "default" = "";
          };
        };

        clock = {
          format = " {:%H:%M}";
          format-alt = " {:%Y-%m-%d}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            format = {
              months = "<span color='#ffead3'><b>{}</b></span>";
              days = "<span color='#ecc6d9'><b>{}</b></span>";
              weeks = "<span color='#99ffdd'><b>W{}</b></span>";
              today = "<span color='#ff6699'><b><u>{}</u></b></span>";
            };
          };
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "󰝟 Muted";
          on-click = "pavucontrol";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [
              ""
              ""
              ""
            ];
          };
        };

        network = {
          format-wifi = "  {signalStrength}%";
          format-ethernet = "󰈀 Wired";
          tooltip-format = "{ifname} via {gwaddr}";
          format-linked = "{ifname} (No IP)";
          format-disconnected = "⚠ Disconnected";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
        };

        cpu = {
          format = " {usage}%";
          tooltip = false;
        };

        memory = {
          format = " {}%";
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = " {capacity}%";
          format-plugged = " {capacity}%";
          format-alt = "{time} {icon}";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
        };

        tray = {
          spacing = 10;
        };

        "custom/power" = {
          format = "⏻";
          on-click = "wlogout";
          tooltip = false;
        };
      };
    };

    style = lib.mkForce ''
      * {
        border: none;
        border-radius: 0;
        font-family: "JetBrainsMono Nerd Font", "Roboto Mono", sans-serif;
        font-weight: bold;
        font-size: 14px;
        min-height: 0;
      }

      window#waybar {
        background: transparent;
      }

      /* Bar Modules */
      .modules-left, .modules-center, .modules-right {
        background: alpha(@base00, 0.9);
        border: 2px solid @base0E;
        border-radius: 24px;
        padding: 4px 16px;
      }

      #custom-launcher {
        font-size: 18px;
        color: @base0D;
        margin-right: 15px;
        padding-left: 10px;
        transition: ${betterTransition};
      }

      #custom-launcher:hover {
        color: @base0E;
      }

      #workspaces button {
        padding: 0 5px;
        color: @base05;
        border-radius: 6px;
        transition: ${betterTransition};
      }

      #workspaces button:hover {
        background: @base02;
        color: @base0E;
      }

      #workspaces button.active {
        background: @base0E;
        color: @base00;
        padding: 0 12px;
      }

      #workspaces button.focused {
        background: @base0E;
        color: @base00;
      }

      #clock, #custom-mangolayout, #pulseaudio, #network, #cpu, #memory, #battery, #tray {
        padding: 0 10px;
        color: @base05;
        transition: ${betterTransition};
      }

      #clock {
        color: @base0B;
      }

      #custom-mangolayout {
        color: @base0E;
      }

      #pulseaudio {
        color: @base0D;
      }

      #network {
        color: @base0C;
      }

      #cpu {
        color: @base08;
      }

      #memory {
        color: @base09;
      }

      #battery {
        color: @base0A;
      }

      #battery.charging {
        color: @base0B;
      }

      #battery.warning:not(.charging) {
        color: @base09;
      }

      #battery.critical:not(.charging) {
        color: @base08;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      #custom-power {
        color: @base08;
        padding-right: 10px;
        margin-right: 5px;
        margin-left: 10px;
        font-size: 16px;
        transition: ${betterTransition};
      }

      #custom-power:hover {
        color: @base0E;
      }

      @keyframes blink {
        to {
          color: @base00;
          background-color: @base08;
        }
      }

      tooltip {
        background: @base00;
        border: 2px solid @base0E;
        border-radius: 12px;
      }

      tooltip label {
        color: @base05;
      }
    '';
  };
}

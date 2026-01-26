{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.programs.mangowc;

  rebuildScript = pkgs.writeShellScriptBin "rebuild-nixos-notify" ''
    # Ask for password
    PASSWORD=$(${pkgs.zenity}/bin/zenity --password --title="NixOS Rebuild" --text="Enter sudo password:") || exit 1

    # Send initial notification
    NOTIFY_ID=$(${pkgs.libnotify}/bin/notify-send -p -t 0 -i system-software-update "System Update" "Rebuilding NixOS... ⏳")

    # Run rebuild in background
    (echo "$PASSWORD" | sudo -S nixos-rebuild switch --flake $HOME/nixosConfig#$(hostname) > /tmp/nixos-rebuild.log 2>&1) &
    PID=$!

    wait $PID
    EXIT_CODE=$?

    # Final notification
    if [ $EXIT_CODE -eq 0 ]; then
       ${pkgs.libnotify}/bin/notify-send -r "$NOTIFY_ID" -t 5000 -i software-update-available "System Update" "Rebuild Complete! ✅"
    else
       ${pkgs.libnotify}/bin/notify-send -r "$NOTIFY_ID" -t 5000 -i dialog-error "System Update" "Rebuild Failed! ❌\nCheck /tmp/nixos-rebuild.log"
    fi
  '';

  hotkeysScript = pkgs.writeShellScriptBin "show-hotkeys" ''
    ${pkgs.gnugrep}/bin/grep 'bind=' ~/.config/mango/config.conf \
      | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*bind=//' \
      | ${pkgs.gawk}/bin/awk -F, '{printf "%-15s + %-10s  ->  ", $1, $2; for(i=3;i<=NF;i++) printf "%s ", $i; print ""}' \
      | ${pkgs.wofi}/bin/wofi --dmenu --prompt 'Hotkeys' --width 800 --height 500
  '';

  betterTransition = "all 0.3s cubic-bezier(.55,-0.68,.48,1.682)";

  mangoWaybarStyle = ''
    * {
      border: none;
      border-radius: 0;
      font-family: "JetBrainsMono Nerd Font", "Roboto Mono", sans-serif;
      font-weight: bold;
      font-size: 20px;
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
      font-size: 24px;
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
      font-size: 22px;
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
in
{
  options.programs.mangowc = {
    enable = lib.mkEnableOption "mangowc";
  };

  config = lib.mkIf cfg.enable {
    services.fnott = {
      enable = !config.environments.wsl.enable;
      settings = lib.mkForce {
        main = {
          anchor = "top-right";
          stacking-order = "top-down";
          min-width = 400;
          title-font = "JetBrainsMono Nerd Font:style=Bold:size=16";
          summary-font = "JetBrainsMono Nerd Font:style=Bold:size=16";
          body-font = "JetBrainsMono Nerd Font:style=Bold:size=14";
          border-size = 2;
          border-radius = 24;
          background = "00000000";
          border-color = "${config.lib.stylix.colors.base05}ff";
          padding-vertical = 20;
          padding-horizontal = 20;
        };
        low = {
          background = "00000000";
          title-color = "${config.lib.stylix.colors.base05}ff";
          summary-color = "${config.lib.stylix.colors.base05}ff";
          body-color = "${config.lib.stylix.colors.base05}ff";
        };
        normal = {
          background = "00000000";
          title-color = "${config.lib.stylix.colors.base0D}ff";
          summary-color = "${config.lib.stylix.colors.base05}ff";
          body-color = "${config.lib.stylix.colors.base05}ff";
        };
        critical = {
          background = "00000000";
          border-color = "${config.lib.stylix.colors.base08}ff";
          title-color = "${config.lib.stylix.colors.base08}ff";
          summary-color = "${config.lib.stylix.colors.base08}ff";
          body-color = "${config.lib.stylix.colors.base08}ff";
        };
      };
    };

    home.packages = [
      inputs.mangowc.packages.${pkgs.system}.default
      pkgs.swaybg
      pkgs.wlr-randr
      pkgs.zenity
      pkgs.libnotify
      rebuildScript
      hotkeysScript
    ];

    xdg.configFile."waybar/mango-style.css".text = mangoWaybarStyle;

    xdg.configFile."mango/config.conf".text = ''
      # General Configuration
      mfact=0.7
      border_width=2
      border_color_active=0x33ccff
      border_color_inactive=0x595959

      # Window corner radius in pixels
      border_radius=6
      # Disable radius if only one window is visible
      no_radius_when_single=0

      # Input
      xkb_rules_options=caps:swapescape

      exec=${pkgs.writeShellScript "mango-startup" ''
        # Import environment variables to systemd (crucial for services like fnott)
        ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
        ${pkgs.systemd}/bin/systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

        # Set scaling for all connected outputs
        for output in $(${pkgs.wlr-randr}/bin/wlr-randr | ${pkgs.gnugrep}/bin/grep "^[^ ]" | ${pkgs.gawk}/bin/awk '{print $1}'); do
            ${pkgs.wlr-randr}/bin/wlr-randr --output $output --scale 1.5
        done
        ${pkgs.procps}/bin/pkill swaybg || true
        ${pkgs.swaybg}/bin/swaybg -i ${config.stylix.image} &
        ${pkgs.waybar}/bin/waybar -s $HOME/.config/waybar/mango-style.css &
      ''}

      focus_follows_mouse=false

      # Keybindings (Translated from Hyprland)

      # App Launchers
      bind=SUPER,space,spawn,wofi --show drun --sort-order=alphabetical
      bind=SUPER,B,spawn,brave --new-window --ozone-platform=wayland
      bind=SUPER,A,spawn,brave --new-window --ozone-platform=wayland --app=https://perplexity.ai
      bind=SUPER+CTRL,K,spawn,${hotkeysScript}/bin/show-hotkeys
      bind=SUPER,T,spawn,alacritty
      bind=SUPER,Return,spawn,alacritty

      # Window Management
      bind=SUPER,I,setlayout,tile
      bind=SUPER,S,setlayout,scroller
      bind=SUPER,M,setlayout,monocle
      bind=SUPER,G,setlayout,grid
      bind=SUPER,D,setlayout,deck
      bind=SUPER,C,setlayout,center_tile
      bind=SUPER,R,setlayout,right_tile
      bind=SUPER,V,setlayout,vertical_tile
      bind=SUPER,Z,setlayout,vertical_scroller
      bind=SUPER,X,setlayout,vertical_grid
      bind=SUPER,Y,setlayout,vertical_spiral
      bind=SUPER,U,setlayout,vertical_deck
      bind=SUPER,O,setlayout,tgmix

      bind=SUPER,W,killclient,
      bind=SUPER,Backspace,killclient,
      bind=SUPER+SHIFT,V,togglefloating,
      bind=SUPER+SHIFT,Return,togglefullscreen,
      bind=SUPER+SHIFT,f,togglefullscreen,
      bind=SUPER,f,togglefullscreen,

      # Session Management
      bind=SUPER,Escape,spawn,hyprlock
      bind=SUPER+SHIFT,Escape,quit,
      bind=SUPER+CTRL,Escape,spawn,reboot
      bind=SUPER+SHIFT+CTRL,Escape,spawn,systemctl poweroff
      bind=SUPER+SHIFT,P,spawn,wlogout
      bind=SUPER+CTRL,R,reload,
      ${lib.optionalString (
        !config.environments.wsl.enable
      ) "bind=SUPER+SHIFT,r,spawn,${rebuildScript}/bin/rebuild-nixos-notify"}

      # Focus Movement
      bind=SUPER,left,focusdir,left
      bind=SUPER,right,focusdir,right
      bind=SUPER,up,focusdir,up
      bind=SUPER,down,focusdir,down
      bind=SUPER,h,focusdir,left
      bind=SUPER,l,focusdir,right
      bind=SUPER,k,focusdir,up
      bind=SUPER,j,focusdir,down

      # Window Movement (Swapping)
      bind=SUPER+SHIFT,left,exchange_client,left
      bind=SUPER+SHIFT,right,exchange_client,right
      bind=SUPER+SHIFT,up,exchange_client,up
      bind=SUPER+SHIFT,down,exchange_client,down
      bind=SUPER+SHIFT,h,exchange_client,left
      bind=SUPER+SHIFT,l,exchange_client,right
      bind=SUPER+SHIFT,k,exchange_client,up
      bind=SUPER+SHIFT,j,exchange_client,down

      # Layout Orientation / Master Management
      bind=SUPER,comma,incnmaster,-1
      bind=SUPER,period,incnmaster,+1
      bind=SUPER,Tab,switch_layout,next

      # Window Resizing
      bind=SUPER+CTRL,h,setmfact,-0.05
      bind=SUPER+CTRL,l,setmfact,+0.05

      # Workspace (Tag) Switching
      bind=SUPER,1,view,1
      bind=SUPER,2,view,2
      bind=SUPER,3,view,3
      bind=SUPER,4,view,4
      bind=SUPER,5,view,5
      bind=SUPER,6,view,6
      bind=SUPER,7,view,7
      bind=SUPER,8,view,8
      bind=SUPER,9,view,9
      bind=SUPER,0,view,10

      # Move Window to Workspace (Tag)
      bind=SUPER+SHIFT,1,tag,1
      bind=SUPER+SHIFT,2,tag,2
      bind=SUPER+SHIFT,3,tag,3
      bind=SUPER+SHIFT,4,tag,4
      bind=SUPER+SHIFT,5,tag,5
      bind=SUPER+SHIFT,6,tag,6
      bind=SUPER+SHIFT,7,tag,7
      bind=SUPER+SHIFT,8,tag,8
      bind=SUPER+SHIFT,9,tag,9
      bind=SUPER+SHIFT,0,tag,10

      # Screenshots (using hyprshot/hyprpicker as defined in hyprland config)
      bind=,Print,spawn,hyprshot -m region
      bind=SHIFT,Print,spawn,hyprshot -m window
      bind=CTRL,Print,spawn,hyprshot -m output
      bind=SUPER,Print,spawn,hyprpicker -a

      # Volume Control
      bind = NONE, XF86AudioRaiseVolume, spawn_shell, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
      bind=NONE,XF86AudioLowerVolume,spawn_shell,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bind=NONE,XF86AudioMute,spawn_shell,wpctl set-volume @DEFAULT_AUDIO_SINK@ toggle
      bind=NONE,XF86AudioMicMute,spawn_shell,wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

      # Mute Toggle
      bind=NONE,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

      # Brightness Control
      bind=NONE,XF86MonBrightnessUp,spawn_shell,brightnessctl -e4 -n2 set 5%+
      bind=NONE,XF86MonBrightnessDown,spawn_shell,brightnessctl -e4 -n2 set 5%-

      # Media Control
      bind=,XF86AudioNext,spawn,playerctl next
      bind=,XF86AudioPlay,spawn,playerctl play-pause
      bind=,XF86AudioPrev,spawn,playerctl previous

      # 3-finger: Window focus
      gesturebind=none,left,3,focusdir,left
      gesturebind=none,right,3,focusdir,right
      gesturebind=none,up,3,focusdir,up
      gesturebind=none,down,3,focusdir,down

      # 4-finger: Workspace navigation
      gesturebind=none,left,4,viewtoleft_have_client
      gesturebind=none,right,4,viewtoright_have_client
      gesturebind=none,up,4,toggleoverview
      gesturebind=none,down,4,toggleovervie
    '';
  };
}

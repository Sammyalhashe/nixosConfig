{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.programs.mangowc;
in
{
  options.programs.mangowc = {
    enable = lib.mkEnableOption "mangowc";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ inputs.mangowc.packages.${pkgs.system}.default ];

    xdg.configFile."mango/config.conf".text = ''
      # General Configuration
      border_width=2
      border_color_active=0x33ccff
      border_color_inactive=0x595959
      exec=hyprpaper

      # Keybindings (Translated from Hyprland)

      # App Launchers
      bind=SUPER,space,spawn,wofi --show drun --sort-order=alphabetical
      bind=SUPER,T,spawn,alacritty
      bind=SUPER,Return,spawn,alacritty

      # Window Management
      bind=SUPER,W,killclient,
      bind=SUPER,Backspace,killclient,
      bind=SUPER,V,togglefloating,
      bind=SUPER+SHIFT,Return,fullscreen,

      # Session Management
      bind=SUPER,Escape,spawn,hyprlock
      bind=SUPER+SHIFT,Escape,quit,
      bind=SUPER+CTRL,Escape,spawn,reboot
      bind=SUPER+SHIFT+CTRL,Escape,spawn,systemctl poweroff

      # Focus Movement
      bind=SUPER,left,focusdir,left
      bind=SUPER,right,focusdir,right
      bind=SUPER,up,focusdir,up
      bind=SUPER,down,focusdir,down
      bind=SUPER,h,focusdir,left
      bind=SUPER,l,focusdir,right
      bind=SUPER,k,focusdir,up
      bind=SUPER,j,focusdir,down

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

      # Volume / Brightness
      bind=,XF86AudioRaiseVolume,spawn,wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
      bind=,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bind=,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bind=,XF86AudioMicMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      bind=,XF86MonBrightnessUp,spawn,brightnessctl -e4 -n2 set 5%+
      bind=,XF86MonBrightnessDown,spawn,brightnessctl -e4 -n2 set 5%-

      # Media Control
      bind=,XF86AudioNext,spawn,playerctl next
      bind=,XF86AudioPlay,spawn,playerctl play-pause
      bind=,XF86AudioPrev,spawn,playerctl previous
    '';
  };
}

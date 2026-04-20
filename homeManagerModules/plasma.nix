{
  config,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:
let
  isKDE =
    osConfig != null
    && (osConfig.host.enableKDE or false)
    && !(osConfig.host.isHeadless or false);
in
{
  config = lib.mkIf isKDE {
    # --- Kvantum Qt theme engine ---
    home.packages = with pkgs; [
      kdePackages.qtstyleplugin-kvantum
      libsForQt5.qtstyleplugin-kvantum
    ];

    qt = {
      enable = true;
      style.name = "kvantum";
      platformTheme.name = "kde";
    };

    xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=KvFlatDark
    '';

    # --- Plasma workspace and panel configuration ---
    programs.plasma = {
      enable = true;

      workspace = {
        clickItemTo = "select";
        theme = "breeze-dark";
        colorScheme = "BreezeDark";
        cursor = {
          theme = "Bibata-Modern-Classic";
          size = 64;
        };
        iconTheme = "breeze-dark";
      };

      panels = [
        {
          location = "bottom";
          height = 44;
          floating = true;
          widgets = [
            "org.kde.plasma.kickoff"
            {
              name = "org.kde.plasma.icontasks";
              config.General.launchers = [
                "applications:org.kde.dolphin.desktop"
                "applications:Alacritty.desktop"
              ];
            }
            "org.kde.plasma.marginsseparator"
            {
              name = "org.kde.plasma.systemtray";
            }
            {
              name = "org.kde.plasma.digitalclock";
              config.Appearance = {
                showDate = true;
                use24hFormat = 2;
              };
            }
          ];
        }
      ];

      kwin = {
        titlebarButtons = {
          left = [ "on-all-desktops" ];
          right = [ "minimize" "maximize" "close" ];
        };
      };

      shortcuts = {
        kwin = {
          "Window Close" = "Meta+Q";
          "Window Maximize" = "Meta+F";
          "Switch to Desktop 1" = "Meta+1";
          "Switch to Desktop 2" = "Meta+2";
          "Switch to Desktop 3" = "Meta+3";
          "Switch to Desktop 4" = "Meta+4";
        };
      };
    };
  };
}

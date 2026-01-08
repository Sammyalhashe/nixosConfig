{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.stylix;
  theme = import ../common/stylix-values.nix { inherit pkgs; };
in
{
  options = {
    programs.stylix.enable = mkEnableOption "Whether to enable stylix";
  };
  config = mkIf cfg.enable {
    stylix.enable = true;
    stylix.base16Scheme = theme.base16Scheme;
    stylix.image = theme.image;
    stylix.polarity = theme.polarity;
    stylix.fonts = theme.fonts;

    environment.etc."current-theme".text = "dark";

    specialisation.light.configuration = {
      stylix.polarity = mkForce "light";
      stylix.base16Scheme = mkForce "${pkgs.base16-schemes}/share/themes/gruvbox-light-hard.yaml";
      environment.etc."current-theme".text = mkForce "light";
    };

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "switch-theme" ''
        if [ -f /etc/current-theme ]; then
          CURRENT=$(cat /etc/current-theme)
        else
          CURRENT="dark"
        fi

        if [ "$CURRENT" == "dark" ]; then
           echo "Switching to Light Theme..."
           sudo /nix/var/nix/profiles/system/specialisation/light/bin/switch-to-configuration test
        else
           echo "Switching to Dark Theme..."
           sudo /nix/var/nix/profiles/system/bin/switch-to-configuration test
        fi
      '')
    ];

    security.sudo.extraRules = [
      {
        users = [ "salhashemi2" ];
        commands = [
          {
            command = "/nix/var/nix/profiles/system/specialisation/light/bin/switch-to-configuration";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/nix/var/nix/profiles/system/bin/switch-to-configuration";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    systemd.timers.theme-light = {
      wantedBy = [ "timers.target" ];
      partOf = [ "theme-light.service" ];
      timerConfig = {
        onCalendar = "06:00";
      };
    };
    systemd.services.theme-light = {
      serviceConfig.Type = "oneshot";
      script = "/nix/var/nix/profiles/system/specialisation/light/bin/switch-to-configuration test";
    };

    systemd.timers.theme-dark = {
      wantedBy = [ "timers.target" ];
      partOf = [ "theme-dark.service" ];
      timerConfig = {

        onCalendar = "17:30";
      };
    };
    systemd.services.theme-dark = {
      serviceConfig.Type = "oneshot";
      script = "/nix/var/nix/profiles/system/bin/switch-to-configuration test";
    };
  };
}

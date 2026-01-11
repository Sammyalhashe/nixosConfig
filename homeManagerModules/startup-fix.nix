{ pkgs, lib, ... }:
{
  # Add delay to waybar and hyprpaper services to avoid race with hyprscrolling layout initialization
  systemd.user.services.hyprpaper.Service.ExecStartPre = lib.mkForce [
    "${pkgs.coreutils}/bin/sleep 5"
  ];
  systemd.user.services.waybar.Service.ExecStartPre = lib.mkForce [ "${pkgs.coreutils}/bin/sleep 5" ];
}

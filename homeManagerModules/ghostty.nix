{ pkgs, ... }:
{
  xdg.configFile."ghostty/config".text = ''
    command = ${pkgs.nushell}/bin/nu --login
  '';
}

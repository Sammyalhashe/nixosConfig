{ pkgs, lib, ... }:
{
  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then null else pkgs.ghostty;
    settings = {
      command = "${pkgs.nushell}/bin/nu --login";
      font-size = 14;
    };
  };
}

{ config, pkgs, lib, ... }:
{
  options.crush = {
    enable = lib.mkEnableOption "crush, a CLI tool for interacting with language models";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.crush;
      description = "The crush package to use.";
    };
  };

  config = lib.mkIf config.crush.enable {
    environment.systemPackages = [ config.crush.package ];
  };
}
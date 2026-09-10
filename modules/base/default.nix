{
  lib,
  pkgs,
  ...
}:
{
  # Baseline every NixOS host converges on. Everything here is mkDefault, so a
  # host can still override it locally; the point is that a host should only
  # need to say something when it differs.
  #
  # These values were previously repeated verbatim across five to seven host
  # files -- time.timeZone in five, the nine-key extraLocaleSettings block
  # byte-identical in two, and the home-manager pair in four (where it was
  # already a no-op, since common/home-manager-config.nix sets both).

  time.timeZone = lib.mkDefault "America/New_York";

  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  i18n.extraLocaleSettings = lib.mkDefault {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Needed on every host if only to evaluate this flake.
  environment.systemPackages = [ pkgs.git ];

  # LAN name resolution. Kept as a literal rather than derived from hosts.nix
  # because raspberrypi (11.125.37.99) is not a NixOS host and so has no entry
  # there; folding it in is a follow-up.
  networking.extraHosts = lib.mkDefault ''
    11.125.37.101 mothership
    11.125.37.175 oldboy
    11.125.37.99  raspberrypi
    11.125.37.98  filestore
    11.125.37.135 homebase
  '';
}

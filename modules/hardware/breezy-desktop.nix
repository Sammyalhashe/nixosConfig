{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

lib.mkIf config.host.enableBreezy {
  # Install breezy-desktop UI, KWin effect, and xr-driver
  environment.systemPackages = [
    inputs.breezy-desktop.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.breezy-desktop.packages.${pkgs.stdenv.hostPlatform.system}.breezy-kwin
    inputs.breezy-desktop.inputs.xr-driver.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # udev rules for XR glasses USB access
  services.udev.packages = [
    inputs.breezy-desktop.inputs.xr-driver.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Required kernel module for virtual input devices
  boot.kernelModules = [ "uinput" ];

  # xr-driver systemd system service — runs the driver daemon
  systemd.services.xr-driver = {
    description = "XR user-space driver";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${
        inputs.breezy-desktop.inputs.xr-driver.packages.${pkgs.stdenv.hostPlatform.system}.default
      }/bin/xr_driver";
      User = config.host.username;
      Group = "input";
      Restart = "always";
      RestartSec = 3;
    };
  };
}

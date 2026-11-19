{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf mkOption types;
in
{
  # options.host.enableHardwareWallets = mkOption {
  #   type = types.bool;
  #   default = false;
  #   description = "Whether to enable hardware wallet support (Ledger, Trezor, OneKey).";
  # };

  config = mkIf config.host.enableHardwareWallets {
    hardware.ledger.enable = true;
    services.trezord.enable = true;

    environment.systemPackages = with pkgs; [
      ledger-live-desktop
      (appimageTools.wrapType2 {
        pname = "leodex";
        version = "beta";
        src = fetchurl {
          # Redirect endpoint, not versioned: the hash breaks when a new beta ships.
          url = "https://leodex.io/download/desktop/linux-x86_64?channel=beta&kind=installer";
          name = "leodex.AppImage";
          hash = "sha256-VILD6+zZQEfSagjHeV4yvap47iR0JwoqDamRe+WceBA=";
        };
      })
      # OneKey disabled
      # (appimageTools.wrapType2 {
      #   pname = "onekey-wallet";
      #   version = "4.20.0";
      #   src = fetchurl {
      #     url = "https://github.com/OneKeyHQ/app-monorepo/releases/download/v6.5.0/OneKey-Wallet-6.5.0-linux-x86_64.AppImage";
      #     hash = "sha256-pxbzIAFQjWSOtj/isoUBm141jS3Ec7zUaWTKWRKoeVE=";
      #   };
      # })
    ];
  };
}

{ config, lib, ... }:

{
  config = lib.mkIf config.host.enableSnap {
    services.snap.enable = true;

    # Required, not optional. snapd builds an AppArmor confinement profile for
    # every snap at startup and shells out to apparmor_parser to compile it.
    # With AppArmor off that binary does not exist, and snapd dies with
    #
    #   AppArmor status: apparmor not enabled
    #   apparmor parser err: file does not exist
    #   error trying to compare the snap system key
    #
    # then trips its restart limit, which surfaces as snapd.socket reporting
    # 'service-start-limit-hit'. Enabling this also inserts apparmor into the
    # kernel LSM stack, which is the half that a bare apparmor_parser package
    # would not give us.
    security.apparmor.enable = true;
  };
}

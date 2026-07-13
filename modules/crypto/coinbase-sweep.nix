{ config, lib, pkgs, ... }:

let
  pythonEnv = pkgs.python313.withPackages (
    ps: with ps; [
      requests
      coinbase-advanced-py
    ]
  );
in
lib.mkIf config.host.enableCoinbaseSweep {
  # 1. Define the automation execution runner service
  systemd.services.coinbase-weekly-sweep = {
    description = "Automated weekly 5% crypto reduction transfer to self-custody";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = config.host.username;

      # Directly call the custom Python interpreter and feed it the script file path
      ExecStart = "${pythonEnv}/bin/python ${./withdraw_to_hardware.py}";
    };
  };

  # 2. Define the timing sequence trigger
  systemd.timers.coinbase-weekly-sweep = {
    description = "Triggers the Coinbase sweep script every Sunday at midnight";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun *-*-* 00:00:00";
      Persistent = true;
    };
  };
}

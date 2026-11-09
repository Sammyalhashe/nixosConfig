{
  config,
  lib,
  pkgs,
  ...
}:
let
  publish = pkgs.writeShellApplication {
    name = "ntfy-publish";
    runtimeInputs = [ pkgs.curl ];
    text = ''
      if [ $# -ne 4 ]; then
        echo "usage: ntfy-publish TOPIC TITLE TAGS PRIORITY < message" >&2
        exit 2
      fi
      curl -fsS --retry 3 --max-time 20 \
        -H "Authorization: Bearer $(cat ${config.sops.secrets.NTFY_ALERTS_TOKEN.path})" \
        -H "Title: $2" -H "Tags: $3" -H "Priority: $4" \
        --data-binary @- "https://ntfy.salh.xyz/$1" > /dev/null
    '';
  };

  # Notifies once per change: a service newly failing or recovering, or a
  # filesystem crossing 90%. push-to-cachix reports to the deploys topic itself.
  check = pkgs.writeShellApplication {
    name = "ntfy-check-health";
    runtimeInputs = [
      publish
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.gawk
      pkgs.systemd
      pkgs.hostname
    ];
    text = ''
      state=/var/lib/ntfy-alerts
      host=$(hostname)
      touch "$state/failed" "$state/disk"

      systemctl list-units --type=service --state=failed --plain --no-legend --no-pager \
        | awk '{print $1}' \
        | { grep -v -E '^(push-to-cachix(-retry)?|ntfy-.*)\.service$' || true; } \
        | sort > "$state/failed.new"
      comm -13 "$state/failed" "$state/failed.new" | while read -r unit; do
        journalctl -u "$unit" -n 15 --no-pager -o cat | tail -c 3000 \
          | ntfy-publish alerts "$host: $unit failed" warning high
      done
      comm -23 "$state/failed" "$state/failed.new" | while read -r unit; do
        echo "$unit is running again." | ntfy-publish alerts "$host: $unit recovered" white_check_mark default
      done
      mv "$state/failed.new" "$state/failed"

      df -P -x tmpfs -x devtmpfs -x overlay -x squashfs -x efivarfs \
        | awk 'NR > 1 && int($5) >= 90 {print $6, $5}' | sort > "$state/disk.new"
      comm -13 <(cut -d' ' -f1 "$state/disk") <(cut -d' ' -f1 "$state/disk.new") | while read -r mount; do
        grep "^$mount " "$state/disk.new" | ntfy-publish alerts "$host: $mount is almost full" floppy_disk high
      done
      mv "$state/disk.new" "$state/disk"
    '';
  };
in
{
  options.host.ntfy.publish = lib.mkOption {
    type = lib.types.package;
    readOnly = true;
    default = publish;
    description = "`ntfy-publish TOPIC TITLE TAGS PRIORITY < message`, authenticated as the alerts user.";
  };

  config = {
    sops.secrets.NTFY_ALERTS_TOKEN = { };

    systemd.services.ntfy-check-health = {
      description = "Report failed services and full disks to ntfy";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe check;
        StateDirectory = "ntfy-alerts";
      };
    };

    systemd.timers.ntfy-check-health = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "5min";
      };
    };
  };
}

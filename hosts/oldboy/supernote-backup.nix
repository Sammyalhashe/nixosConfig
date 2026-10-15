{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Dedicated user on filestore, confined by rrsync to its backup directory.
  backupUser = "supernote-backup";
  # Raw IP, not the bare "filestore" hostname: oldboy has no hosts entry or
  # confirmed search domain for it (only starshipwsl does, via an explicit
  # extraHosts line). Matches the deploy-rs convention of addressing hosts by
  # LAN IP. Filestore's IP is the single source of truth in hosts.nix.
  destHost = "11.125.37.98";
  dumpDir = "/supernote/db-dump";

  # Single dump implementation shared by the daily timer and the
  # podman-supernote-service ExecStartPre crash-loop dump. "daily" also
  # manages the weekly/monthly hardlink tree and prunes all four dirs;
  # "prestart" only dumps into prestart/, rate-limited to once per hour.
  dumpScript = pkgs.writeShellApplication {
    name = "supernote-db-dump";
    runtimeInputs = with pkgs; [
      podman
      coreutils
      findutils
    ];
    text = ''
      mode="''${1:?usage: supernote-db-dump daily|prestart}"
      case "$mode" in
        daily | prestart) ;;
        *)
          echo "<3>supernote-db-dump: unknown mode '$mode' (want daily|prestart)" >&2
          exit 1
          ;;
      esac

      mkdir -p "${dumpDir}"/{daily,weekly,monthly,prestart}

      # Crash-loop guard: podman-supernote-service restarting repeatedly
      # would otherwise hammer mariadb-dump every few seconds.
      if [ "$mode" = prestart ]; then
        recent=$(find "${dumpDir}/prestart" -maxdepth 1 -name 'supernotedb-*.sql' -newermt '-60 minutes' -print -quit)
        if [ -n "$recent" ]; then
          echo "supernote-db-dump: recent prestart dump exists, skipping"
          exit 0
        fi
      fi

      waited=0
      until podman exec supernote-mariadb mariadb-admin ping >/dev/null 2>&1; do
        waited=$((waited + 1))
        if [ "$waited" -ge 60 ]; then
          echo "<3>supernote-db-dump: mariadb not ready after 60s" >&2
          exit 1
        fi
        sleep 1
      done

      ts=$(date +%Y-%m-%dT%H-%M-%S)
      out="${dumpDir}/$mode/supernotedb-$ts.sql"
      tmp="$out.tmp"

      if ! podman exec supernote-mariadb sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mariadb-dump -uroot --single-transaction supernotedb' >"$tmp"; then
        echo "<3>supernote-db-dump: mariadb-dump failed" >&2
        rm -f "$tmp"
        exit 1
      fi

      # mariadb-dump always ends with this marker; its absence means a
      # truncated/torn dump (e.g. the container was killed mid-dump).
      if [[ "$(tail -n1 "$tmp")" != "-- Dump completed"* ]]; then
        echo "<3>supernote-db-dump: dump missing trailing completion marker, discarding" >&2
        rm -f "$tmp"
        exit 1
      fi
      mv "$tmp" "$out"

      prune() {
        local dir=$1 keep=$2
        find "$dir" -maxdepth 1 -name 'supernotedb-*.sql' | sort | head -n "-$keep" | xargs -r rm -f
      }

      if [ "$mode" = daily ]; then
        ln -sf "daily/$(basename "$out")" "${dumpDir}/supernotedb-latest.sql"

        if [ -z "$(find "${dumpDir}/weekly" -maxdepth 1 -name 'supernotedb-*.sql' -newermt '-7 days' -print -quit)" ]; then
          ln "$out" "${dumpDir}/weekly/$(basename "$out")"
        fi

        month=$(date +%Y-%m)
        if [ -z "$(find "${dumpDir}/monthly" -maxdepth 1 -name "supernotedb-$month-*.sql" -print -quit)" ]; then
          ln "$out" "${dumpDir}/monthly/$(basename "$out")"
        fi

        prune "${dumpDir}/daily" 7
        prune "${dumpDir}/weekly" 8
        prune "${dumpDir}/monthly" 12
      else
        prune "${dumpDir}/prestart" 10
      fi
    '';
  };

  schemaStateDir = "supernote-schema-check";
  vendorSchemaUrl = "https://supernote-private-cloud.supernote.com/cloud/supernotedb.sql";

  # Report-only drift check: compares the vendor schema's CREATE TABLE names
  # against SHOW TABLES, so a silent image bump that adds a table (like
  # t_user_mfa in 26.10.09) is caught before it causes a confusing runtime
  # error. Never applies SQL.
  schemaCheckScript = pkgs.writeShellApplication {
    name = "supernote-schema-check";
    runtimeInputs = with pkgs; [
      podman
      coreutils
      gnugrep
      gnused
      curl
    ];
    text = ''
      state_dir="''${STATE_DIRECTORY:-/var/lib/${schemaStateDir}}"
      cached="$state_dir/supernotedb.sql"

      if ! curl -fsSL --connect-timeout 10 "${vendorSchemaUrl}" -o "$cached.new"; then
        if [ -s "$cached" ]; then
          echo "supernote-schema-check: could not fetch vendor schema, using cached copy" >&2
        else
          echo "supernote-schema-check: could not fetch vendor schema and no cache available, skipping" >&2
          exit 0
        fi
      else
        mv "$cached.new" "$cached"
      fi

      vendor_tables=$(
        grep -oiE '^CREATE TABLE( IF NOT EXISTS)?[[:space:]]+(supernotedb\.)?`?[A-Za-z0-9_]+`?' "$cached" \
          | sed -E 's/^CREATE TABLE( IF NOT EXISTS)?[[:space:]]+//I' \
          | sed -E 's/^supernotedb\.//I' \
          | tr -d '`'
      )
      if [ -z "$vendor_tables" ]; then
        echo "<3>supernote-schema-check: failed to parse any CREATE TABLE statements from vendor schema" >&2
        exit 1
      fi

      live_tables=$(podman exec supernote-mariadb sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mariadb -uroot -NB -e "SHOW TABLES" supernotedb')

      missing=""
      while IFS= read -r table; do
        [ -z "$table" ] && continue
        if ! grep -qxF "$table" <<<"$live_tables"; then
          missing="$missing $table"
        fi
      done <<<"$vendor_tables"

      if [ -n "$missing" ]; then
        echo "<3>supernote-schema-check: missing tables:$missing" >&2
        for table in $missing; do
          echo "--- $table ---" >&2
          start=$(grep -niE "^CREATE TABLE( IF NOT EXISTS)?[[:space:]]+(supernotedb\.)?\`?''${table}\`?[[:space:]]*\(" "$cached" | head -n1 | cut -d: -f1)
          if [ -n "$start" ]; then
            end=$(awk -v s="$start" 'NR>s && /^CREATE TABLE/{print NR; exit}' "$cached")
            if [ -z "$end" ]; then end=$(wc -l <"$cached"); else end=$((end - 1)); fi
            sed -n "''${start},''${end}p" "$cached" >&2
          fi
        done
        exit 1
      fi

      echo "supernote-schema-check: all vendor tables present"
    '';
  };
in
{
  # Dump the live MariaDB database to a plain SQL file before backing up.
  # Raw-copying db_data/redis_data while the containers are running risks a
  # torn, non-restorable snapshot (InnoDB's multi-file storage isn't safe to
  # rsync mid-write); a proper dump is the only reliable way to back up a live
  # database. supernote-backup excludes the raw datadirs and relies on this.
  systemd.services."supernote-db-dump" = {
    description = "Dump the Supernote MariaDB database for backup";
    after = [ "podman-supernote-mariadb.service" ];
    requires = [ "podman-supernote-mariadb.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "${lib.getExe dumpScript} daily";
    };
  };

  systemd.services."supernote-backup" = {
    description = "Rsync /supernote to filestore for backup";
    after = [
      "supernote-db-dump.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    requires = [ "supernote-db-dump.service" ];
    path = [
      pkgs.rsync
      pkgs.openssh
    ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      rsync -az --delete --mkpath \
        --exclude=/sndata/db_data \
        --exclude=/sndata/redis_data \
        -e "ssh -i /etc/ssh/ssh_host_ed25519_key -o StrictHostKeyChecking=accept-new" \
        /supernote/ ${backupUser}@${destHost}:
    '';
  };

  systemd.timers."supernote-backup" = {
    description = "Daily Supernote backup to filestore";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };

  # Crash-loop-safe dump taken right before the container stack (re)starts,
  # so a manual restart or an image bump always leaves a fresh dump behind
  # even if the next scheduled daily dump is hours away. "-" so a failed dump
  # never fails podman-supernote-service's start (a failed unit would roll
  # back deploy-rs).
  systemd.services.podman-supernote-service.serviceConfig.ExecStartPre = [
    "-${lib.getExe dumpScript} prestart"
  ];

  systemd.services."supernote-schema-check" = {
    description = "Check the live Supernote schema against the vendor's for drift";
    requires = [ "podman-supernote-mariadb.service" ];
    after = [
      "podman-supernote-mariadb.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      StateDirectory = schemaStateDir;
      ExecStart = lib.getExe schemaCheckScript;
    };
  };

  systemd.timers."supernote-schema-check" = {
    description = "Periodic Supernote schema drift check";
    wantedBy = [ "timers.target" ];
    partOf = [ "podman-supernote-service.service" ];
    timerConfig = {
      OnCalendar = "daily";
      OnActiveSec = "5min";
      Persistent = true;
    };
  };
}

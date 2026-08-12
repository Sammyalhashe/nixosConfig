{ config, pkgs, ... }:
let
  # root, not salhashemi2: /backup on filestore is root-owned (created
  # implicitly by vaultwarden-backup.service, which also runs as root), so a
  # non-root user can't --mkpath a new directory under it. root is already
  # trusted via trusted-keys.nix, same as salhashemi2.
  backupUser = "root";
  # Raw IP, not the bare "filestore" hostname: oldboy has no hosts entry or
  # confirmed search domain for it (only starshipwsl does, via an explicit
  # extraHosts line). Matches the deploy-rs convention of addressing hosts by
  # LAN IP. Filestore's IP is the single source of truth in hosts.nix.
  destHost = "11.125.37.98";
  destDir = "/backup/oldboy-supernote";
  dumpDir = "/supernote/db-dump";
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
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      # Provides $MYSQL_PASSWORD for the enote fallback below -- same secret
      # the app container itself uses, so it's guaranteed to be a working
      # credential if root's unix_socket auth isn't available.
      EnvironmentFile = [ config.sops.secrets.filestore_container_env.path ];
    };
    script = ''
      set -euo pipefail
      mkdir -p ${dumpDir}
      TS=$(date +%Y-%m-%dT%H-%M-%S)
      OUT="${dumpDir}/supernotedb-$TS.sql"
      # MariaDB's entrypoint defaults root to unix_socket auth (no password)
      # when no MYSQL_ROOT_PASSWORD-family var is set; if that's not the case
      # here, fall back to the app's own `enote` credential instead.
      if ! podman exec supernote-mariadb mariadb-dump -uroot supernotedb > "$OUT" 2>/tmp/supernote-dump.err; then
        echo "root dump failed (see /tmp/supernote-dump.err), retrying as enote" >&2
        podman exec -e MYSQL_PWD="$MYSQL_PASSWORD" supernote-mariadb mariadb-dump -uenote supernotedb > "$OUT"
      fi
      ln -sf "$OUT" ${dumpDir}/supernotedb-latest.sql
      # Keep a week of daily dumps; rsync --delete below prunes the same
      # files on the filestore side.
      find ${dumpDir} -maxdepth 1 -name 'supernotedb-*.sql' -mtime +7 -delete
    '';
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
        /supernote/ ${backupUser}@${destHost}:${destDir}/
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
}

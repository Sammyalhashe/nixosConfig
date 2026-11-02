{
  pkgs,
  inputs,
  ...
}:
let
  port = 2310;
  todo = inputs.todo.packages.${pkgs.stdenv.hostPlatform.system}.default;
  stateDir = "/var/lib/todo-http";
  # podman's default range for created bridge networks; terminus-net is
  # recreated on restart, so its subnet and interface name are not stable.
  podmanNetworks = "10.89.0.0/16";
  firewallRule = "nixos-fw -p tcp -s ${podmanNetworks} --dport ${toString port} -j nixos-fw-accept";
in
{
  # SELECT-only MariaDB user for the endpoint. The password is generated on
  # oldboy and never leaves it, so it needs no sops entry.
  systemd.services.todo-http-db-user = {
    description = "Provision the read-only MariaDB user for todo-http";
    after = [ "podman-supernote-mariadb.service" ];
    requires = [ "podman-supernote-mariadb.service" ];
    partOf = [ "podman-supernote-mariadb.service" ];
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [
      podman
      coreutils
      openssl
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StateDirectory = "todo-http";
      StateDirectoryMode = "0700";
      UMask = "0077";
    };
    script = ''
      pw_file=${stateDir}/db-password
      [ -s "$pw_file" ] || openssl rand -hex 32 > "$pw_file"
      pw=$(cat "$pw_file")

      waited=0
      until podman exec supernote-mariadb mariadb-admin ping >/dev/null 2>&1; do
        waited=$((waited + 1))
        if [ "$waited" -ge 60 ]; then
          echo "<3>todo-http-db-user: mariadb not ready after 60s" >&2
          exit 1
        fi
        sleep 1
      done

      podman exec -i supernote-mariadb sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mariadb -uroot' <<EOF
      CREATE USER IF NOT EXISTS 'todo_reader'@'%' IDENTIFIED BY '$pw';
      ALTER USER 'todo_reader'@'%' IDENTIFIED BY '$pw';
      GRANT SELECT ON supernotedb.t_schedule_task TO 'todo_reader'@'%';
      GRANT SELECT ON supernotedb.u_user TO 'todo_reader'@'%';
      EOF
    '';
  };

  # Read-only task feed for the TRMNL todo screen: GET /tasks, GET /healthz.
  systemd.services.todo-http = {
    description = "Read-only HTTP feed of Supernote tasks";
    after = [ "todo-http-db-user.service" ];
    requires = [ "todo-http-db-user.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      DynamicUser = true;
      RuntimeDirectory = "todo-http";
      RuntimeDirectoryMode = "0700";
      LoadCredential = "db-password:${stateDir}/db-password";
      Restart = "always";
      RestartSec = 5;
      ProtectHome = true;
      PrivateDevices = true;
      CapabilityBoundingSet = "";
    };
    # todo only reads its config from $HOME/.todo.json.
    script = ''
      umask 077
      cat > "$RUNTIME_DIRECTORY/.todo.json" <<EOF
      {"backend":"mariadb","mariadb":{"host":"127.0.0.1","port":3306,"user":"todo_reader","password":"$(cat "$CREDENTIALS_DIRECTORY/db-password")"}}
      EOF
      HOME="$RUNTIME_DIRECTORY" exec ${todo}/bin/todo http --addr 0.0.0.0 --port ${toString port}
    '';
  };

  # Only containers (terminus) may reach the feed; the LAN port stays closed.
  networking.firewall.extraCommands = "iptables -A ${firewallRule}";
  networking.firewall.extraStopCommands = "iptables -D ${firewallRule} || true";
}

{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  notesDir = "/nextcloud/data/salhashemi2/files/Notes/Inbox";
  python = pkgs.python3.withPackages (ps: [ ps.pymysql ]);
  quickNotes = inputs.vicinae-quick-notes.packages.${pkgs.stdenv.hostPlatform.system}.cli;
  syncScript = pkgs.writeTextFile {
    name = "supernote-quicknotes-sync";
    destination = "/bin/supernote-quicknotes-sync";
    executable = true;
    text = ''
      #!${lib.getExe python}
      ${builtins.readFile ./supernote-quicknotes-sync.py}
    '';
  };
in
{
  systemd.services.supernote-quicknotes-sync = {
    description = "Synchronize Nextcloud quick notes with Supernote tasks";
    after = [
      "network-online.target"
      "podman-nextcloud-app.service"
    ];
    wants = [
      "network-online.target"
      "podman-nextcloud-app.service"
    ];
    path = [
      quickNotes
      pkgs.openssh
      pkgs.podman
    ];
    environment.QUICK_NOTES_DIR = notesDir;
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      StateDirectory = "supernote-quicknotes-sync";
      EnvironmentFile = config.sops.secrets.filestore_container_env.path;
      ExecStart = lib.getExe syncScript;
    };
  };

  systemd.timers.supernote-quicknotes-sync = {
    description = "Synchronize quick notes and Supernote tasks every five minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/5";
      Persistent = true;
    };
  };
}

{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  nextcloudFiles = "salhashemi2/files";
  # The pre-split Inbox/"Quick Notes" pair keeps the original state directory so its mappings carry over.
  profiles = {
    inbox = {
      folder = "Notes/Inbox";
      taskList = "Quick Notes";
      tunnelPort = 13308;
      stateDirectory = "supernote-quicknotes-sync";
    };
    personal = {
      folder = "Notes/Personal";
      taskList = "Personal";
      tunnelPort = 13306;
      stateDirectory = "supernote-quicknotes-sync-personal";
    };
    work = {
      folder = "Notes/Work";
      taskList = "Work";
      tunnelPort = 13307;
      stateDirectory = "supernote-quicknotes-sync-work";
    };
  };
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
  systemd.services = lib.mapAttrs' (
    name: profile:
    lib.nameValuePair "supernote-quicknotes-sync-${name}" {
      description = "Synchronize Nextcloud ${name} quick notes with the Supernote ${profile.taskList} list";
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
      environment = {
        QUICK_NOTES_DIR = "/nextcloud/data/${nextcloudFiles}/${profile.folder}";
        NEXTCLOUD_SCAN_PATH = "${nextcloudFiles}/${profile.folder}";
        SUPERNOTE_TASK_LIST = profile.taskList;
        TUNNEL_PORT = toString profile.tunnelPort;
      };
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        StateDirectory = profile.stateDirectory;
        EnvironmentFile = config.sops.secrets.filestore_container_env.path;
        ExecStart = lib.getExe syncScript;
      };
    }
  ) profiles;

  systemd.timers = lib.mapAttrs' (
    name: profile:
    lib.nameValuePair "supernote-quicknotes-sync-${name}" {
      description = "Synchronize ${name} quick notes and Supernote tasks every five minutes";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/5";
        Persistent = true;
      };
    }
  ) profiles;
}

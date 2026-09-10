{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = config.host.username;
in
{
  # Was byte-identical hosts/homebase/webdav.nix and hosts/oldboy/webdav.nix,
  # both of which hardcoded the username in a local `let` rather than reading
  # host.username.
  config = lib.mkIf config.host.enableWebdav {
    # define davfs2 group and user
    users.groups.davfs2 = { };
    users.users.davfs2 = {
      group = "davfs2";
      isSystemUser = true;
    };

    services.davfs2.enable = true;
    services.autofs = {
      enable = true;
      autoMaster =
        let
          mapConf = pkgs.writeText "auto" ''
            nextcloud -fstype=davfs,conf=/home/${user}/.davfs2/davfs.conf,uid=myuid :https\:picloud.local:9001/remote.php/dav/files/${user}/webdav
          '';
        in
        ''
          /home/${user}/webdav file:${mapConf}
        '';
    };
  };
}

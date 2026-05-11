{ pkgs, ... }:
{
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "Sammyalhashe";
        email = "sammy@salh.xyz";
      };
      ui = {
        editor = "nvim";

        diff-editor = "scm-diff-editor";

        color = "always";

        default-command = "log";
      };

      templates = {
        # This is the modern replacement for push-bookmark-prefix.
        # It creates names like "salhashemi2/push-abc123"
        git_push_bookmark = "\"salhashemi2/push-\" ++ change_id.short()";
      };

      git = {
        auto-local-branch = true;
        push = "bookmark";
      };

      revsets = {
        log = "mine() | main@origin";
      };

      revset-aliases = {
        # Shows your current work and recent changes clearly
        "l" = "ancestors(remote_bookmarks().. @, 3) | remote_bookmarks().. @";
      };

      aliases = {
        # Quick aliases for common operations
        l = [
          "log"
          "-r"
          "all()"
        ];
        s = [ "status" ];
        d = [ "describe" ];
        n = [ "new" ];
        u = [ "undo" ];
        # 'Evolve' is a common alias for rebasing onto the remote head
        ev = [
          "rebase"
          "-d"
          "main@origin"
        ];
      };
    };
  };
}

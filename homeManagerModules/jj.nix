{ pkgs, ... }:
{
  programs.jjui = {
    enable = true;
    settings = {
      bindings =
        let
          cancelBinding = scope: action: {
            inherit action scope;
            key = "alt+c";
            desc = "Cancel";
          };
        in
        [
          (cancelBinding "ui" "ui.cancel")
          (cancelBinding "diff" "ui.cancel")
          (cancelBinding "revisions" "revisions.cancel")
          (cancelBinding "revisions.abandon" "revisions.abandon.cancel")
          (cancelBinding "revisions.rebase" "revisions.rebase.cancel")
          (cancelBinding "revisions.squash" "revisions.squash.cancel")
          (cancelBinding "revisions.duplicate" "revisions.duplicate.cancel")
          (cancelBinding "revisions.revert" "revisions.revert.cancel")
          (cancelBinding "revisions.set_parents" "revisions.set_parents.cancel")
          (cancelBinding "revisions.set_bookmark" "revisions.set_bookmark.cancel")
          (cancelBinding "revisions.evolog" "revisions.evolog.cancel")
          (cancelBinding "revisions.inline_describe" "revisions.inline_describe.cancel")
          (cancelBinding "revisions.target_picker" "revisions.target_picker.cancel")
          (cancelBinding "revisions.ace_jump" "revisions.ace_jump.cancel")
          (cancelBinding "revisions.details.confirmation" "revisions.details.confirmation.cancel")
          (cancelBinding "revisions.quick_search.input" "revisions.quick_search.input.cancel")
          (cancelBinding "bookmarks" "bookmarks.cancel")
          (cancelBinding "bookmarks.filter" "bookmarks.cancel")
          (cancelBinding "git" "git.cancel")
          (cancelBinding "git.filter" "git.cancel")
          (cancelBinding "help" "help.cancel")
          (cancelBinding "help.filter" "help.cancel")
          (cancelBinding "choose" "choose.cancel")
          (cancelBinding "choose.filter" "choose.cancel")
          (cancelBinding "input" "input.cancel")
          (cancelBinding "file_search" "file_search.cancel")
          (cancelBinding "undo" "undo.cancel")
          (cancelBinding "redo" "redo.cancel")
          (cancelBinding "status.input" "status.input.cancel")
        ];
    };
  };

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

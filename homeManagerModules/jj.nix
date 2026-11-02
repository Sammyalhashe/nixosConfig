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

        diff-editor = [
          "nvim"
          "-c"
          "DiffEditor $left $right $output"
        ];
        diff-instructions = false;

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
        # Aliases below adapted from https://www.lysator.liu.se/~axl/jj-aliases/
        # Nearest bookmark at or before `to`
        "closest_bookmark(to)" = "heads(::to & bookmarks())";
        # Nearest described, non-empty commit at or before `to`
        "closest_pushable(to)" = "heads(::to & ~description(exact:\"\") & (~empty() | merges()))";
        # Mutable commits reachable from x, plus n levels of ancestors for context
        "stack()" = "stack(@)";
        "stack(x)" = "stack(x, 2)";
        "stack(x, n)" = "ancestors(reachable(x, mutable()), n)";
        # All open work stacks: from @ or authored by me
        "open()" = "stack(mine() | @, 1) ~ hidden()";
        # Explain why r is immutable
        "why_immutable(r)" = "(r & immutable()) | roots(r:: & immutable_heads())";
        "recent()" = "recent(all())";
        "recent(r)" = "r & committer_date(after:\"1 month ago\")";
        # First commit of the current branch (child of trunk)
        "branch_start(to)" = "heads(::to & trunk())+ & ::to";
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
        # Move the closest bookmark up to the latest pushable commit
        tug = [
          "bookmark"
          "advance"
          "--to"
          "closest_pushable(@)"
        ];
        # Rebase every active branch reachable from @ onto trunk
        restack = [
          "rebase"
          "-o"
          "trunk()"
          "-s"
          "roots(trunk()..) & stack()"
        ];
        # Squash the whole current branch into its first commit
        collapse = [
          "squash"
          "-f"
          "branch_start(@)+::@"
          "-t"
          "branch_start(@)"
        ];
        # Queue an empty described commit at the branch tip: jj plan "msg"
        plan = [
          "new"
          "--no-edit"
          "heads(@::)"
          "-m"
        ];
        open = [
          "log"
          "-r"
          "open()"
        ];
        sync = [
          "git"
          "fetch"
          "--all-remotes"
        ];
        long = [
          "log"
          "-T"
          "builtin_log_detailed"
        ];
        short = [
          "log"
          "-T"
          "builtin_log_oneline"
        ];
        blame = [
          "file"
          "annotate"
        ];
      };
    };
  };
}

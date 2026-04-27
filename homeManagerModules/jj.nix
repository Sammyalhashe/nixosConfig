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
    };
  };
}

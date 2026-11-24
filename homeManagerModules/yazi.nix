{
  pkgs,
  ...
}:
{
  programs.yazi = {
    shellWrapperName = "y";
    enable = true;
    plugins = {
      inherit (pkgs.yaziPlugins)
        full-border
        smart-enter
        smart-paste
        toggle-pane
        ;
      smart-tab = ./yazi-plugins/smart-tab.yazi;
      confirm-quit = ./yazi-plugins/confirm-quit.yazi;
    };
    initLua = ''
      require("full-border"):setup()

      Status:children_add(function(self)
        local h = self._current.hovered
        if h and h.link_to then
          return " -> " .. tostring(h.link_to)
        end
        return ""
      end, 3300, Status.LEFT)
    '';
    settings.plugin = {
      prepend_previewers = [
        {
          mime = "image/*";
          run = "noop";
        }
      ];
      prepend_preloaders = [
        {
          mime = "image/*";
          run = "noop";
        }
      ];
    };
    keymap = {
      mgr.prepend_keymap = [
        {
          on = [ "l" ];
          run = "plugin smart-enter";
          desc = "Enter the child directory, or open the file";
        }
        {
          on = [ "<C-s>" ];
          run = "shell nu --block --confirm";
          desc = "Open shell here";
        }
        {
          on = [ "p" ];
          run = "plugin smart-paste";
          desc = "Paste into the hovered directory or CWD";
        }
        {
          on = [
            "t"
            "t"
          ];
          run = "plugin smart-tab";
          desc = "Create a tab and enter the hovered directory";
        }
        {
          on = [ "q" ];
          run = "plugin confirm-quit";
          desc = "Quit, confirming first if several tabs are open";
        }
        {
          on = [ "T" ];
          run = "plugin toggle-pane max-preview";
          desc = "Maximize or restore the preview pane";
        }
        {
          on = [
            "g"
            "r"
          ];
          run = ''shell -- ya emit cd "$(git rev-parse --show-toplevel)"'';
          desc = "Go to the Git repository root";
        }
        {
          on = [ "y" ];
          run = [
            ''shell -- for path in %s; do echo "file://$path"; done | wl-copy -t text/uri-list''
            "yank"
          ];
          desc = "Yank, and copy the files to the Wayland clipboard";
        }
      ];
      input.prepend_keymap = [
        {
          on = [ "<Esc>" ];
          run = "close";
          desc = "Cancel input";
        }
      ];
    };
  };
}

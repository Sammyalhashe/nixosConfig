{
  config,
  pkgs,
  stdenv,
  ...
}:
let
  font = "";
in
{
  programs.alacritty = {
    enable = true;
    settings = {
      terminal.shell = {
        program = "zellij";
        args = [
          "-l"
          "welcome"
        ];
      };
      env = {
        TERM = "xterm-256color";
      };

      keyboard.bindings = [
        {
          chars = "\u0002&";
          key = "W";
          mods = "Command";
        }

        {
          chars = "\u0002c";
          key = "T";
          mods = "Command";
        }

        {
          chars = "\u0002n";
          key = "RBracket";
          mods = "Command|Shift";
        }

        {
          chars = "\u0002p";
          key = "LBracket";
          mods = "Command|Shift";
        }

        {
          chars = "\u0002o";
          key = "RBracket";
          mods = "Command";
        }

        {
          chars = "\u0002;";
          key = "LBracket";
          mods = "Command";
        }

        {
          chars = "\u0002/";
          key = "F";
          mods = "Command";
        }
      ];

      mouse.bindings = [
        {
          action = "PasteSelection";
          mouse = "Middle";
        }
      ];

      selection = {
        semantic_escape_chars = ",│`|:\"' ()[]{}<>";
      };

      window = {
        # decorations = "None";
        # opacity = 0.95;

        dimensions = {
          columns = 110;
          lines = 33;
        };

        padding = {
          x = 0;
          y = 0;
        };
      };
    };
  };
}

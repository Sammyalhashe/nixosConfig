{
  config,
  pkgs,
  stdenv,
  ...
}:
let
  font = "JetBrains Mono";
  shell = {
    program = if config.environments.wsl.enable then "nu" else "zellij";
    args = if config.environments.wsl.enable then [
      "~"
      "-e"
      "nu"
    ] else [
      "-l"
      "welcome"
    ];
  };
in
{
  programs.alacritty = {
    enable = true;
    settings = {
      terminal = {
        inherit shell;
      };
      env = {
        TERM = "xterm-256color";
      };
      font = {
        size = 14.0;
        normal = {
          family = "${font}";
          style = "Regular";
        };
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

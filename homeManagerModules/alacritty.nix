{ config, pkgs, stdenv, ... }:
let
    font = "";
in
{
    programs.alacritty = {
        enable = true;
        settings = {
            general.import = [
                (pkgs.fetchFromGitHub {
                    owner = "alacritty";
                    repo = "alacritty-theme";
                    rev = "5c90d86e6a9c95d47f8dbd1f8597136fa5556376";
                    sha256 = "sha256-Xwb7yiJ1yAEoMi+lHUg//PEe9LaAJbMg2aaIp2tX7jc=";
                } + "/themes/kanagawa_wave.toml")

                # (pkgs.fetchFromGitHub {
                #     owner = "EdenEast";
                #     repo = "nightfox.nvim";
                #     rev = "595ffb8f291fc4a9bef3201a28b7c0379a41cdee";
                #     sha256 = "sha256-bVRI77ikBRECJ9Y6UVgZVO+SH46LBU3MtZUDgAYqXBc=";
                # } + "/extra/dayfox/alacritty.toml")

            ];
            env = {
                TERM = "xterm-256color";
            };
            font = {
                size = 12.0;
                bold = { family = "FantasqueSansM Nerd Font"; };
                italic = { family = "FantasqueSansM Nerd Font"; };
                normal = { family = "FantasqueSansM Nerd Font"; };
                offset = { x = 0; y = 0; };
                glyph_offset = {
                    x = 0;
                    y = 0;
                };
            };

            keyboard.bindings = [

                {
                    chars = "\\u001B[4~";
                    key = "End";
                    mode = "~AppCursor";
                }


                {
                    chars = "\\u001B[5;2~";
                    key = "PageUp";
                    mods = "Shift";
                }


                {
                    chars = "\\u001B[5;5~";
                    key = "PageUp";
                    mods = "Control";
                }


                {
                    chars = "\\u001B[5~";
                    key = "PageUp";

                }


                {
                    chars = "\\u001B[6;2~";
                    key = "PageDown";
                    mods = "Shift";
                }


                {
                    chars = "\\u001B[6;5~";
                    key = "PageDown";
                    mods = "Control";
                }


                {
                    chars = "\\u001B[6~";
                    key = "PageDown";

                }


                {
                    chars = "\\u001B[1;2D";
                    key = "Left";
                    mods = "Shift";
                }


                {
                    chars = "\\u001B[1;5D";
                    key = "Left";
                    mods = "Control";
                }


                {
                    chars = "\\u001B[1;3D";
                    key = "Left";
                    mods = "Alt";
                }


                {
                    chars = "\\u001B[D";
                    key = "Left";
                    mode = "~AppCursor";
                }


                {
                    chars = "\\u001BOD";
                    key = "Left";
                    mode = "AppCursor";
                }


                {
                    chars = "\\u001B[1;2C";
                    key = "Right";
                    mods = "Shift";
                }


                {
                    chars = "\\u001B[1;5C";
                    key = "Right";
                    mods = "Control";
                }


                {
                    chars = "\\u001B[1;3C";
                    key = "Right";
                    mods = "Alt";
                }


                {
                    chars = "\\u001B[C";
                    key = "Right";
                    mode = "~AppCursor";
                }


                {
                    chars = "\\u001BOC";
                    key = "Right";
                    mode = "AppCursor";
                }


                {
                    chars = "\\u001B[1;2A";
                    key = "Up";
                    mods = "Shift";
                }


                {
                    chars = "\\u001B[1;5A";
                    key = "Up";
                    mods = "Control";
                }


                {
                    chars = "\\u001B[1;3A";
                    key = "Up";
                    mods = "Alt";
                }


                {
                    chars = "\\u001B[A";
                    key = "Up";
                    mode = "~AppCursor";
                }


                {
                    chars = "\\u001BOA";
                    key = "Up";
                    mode = "AppCursor";
                }


                {
                    chars = "\\u001B[1;2B";
                    key = "Down";
                    mods = "Shift";
                }


                {
                    chars = "\\u001B[1;5B";
                    key = "Down";
                    mods = "Control";
                }


                {
                    chars = "\\u001B[1;3B";
                    key = "Down";
                    mods = "Alt";
                }


                {
                    chars = "\\u001B[B";
                    key = "Down";
                    mode = "~AppCursor";
                }


                {
                    chars = "\\u001BOB";
                    key = "Down";
                    mode = "AppCursor";
                }


                {
                    chars = "\\u001B[Z";
                    key = "Tab";
                    mods = "Shift";
                }


                {
                    chars = "\\u001BOP";
                    key = "F1";

                }


                {
                    chars = "\\u001BOQ";
                    key = "F2";

                }


                {
                    chars = "\\u001BOR";
                    key = "F3";

                }


                {
                    chars = "\\u001BOS";
                    key = "F4";

                }


                {
                    chars = "\\u001B[15~";
                    key = "F5";

                }


                {
                    chars = "\\u001B[17~";
                    key = "F6";

                }
                

                {
                    chars = "\\u001B[18~";
                    key = "F7";

                }


                {
                    chars = "\\u001B[19~";
                    key = "F8";

                }


                {
                    chars = "\\u001B[20~";
                    key = "F9";

                }


                {
                    chars = "\\u001B[21~";
                    key = "F10";

                }

                {
                    chars = "\\u001B[23~";
                    key = "F11";

                }


                {
                    chars = "\\u001B[24~";
                    key = "F12";

                }


                {
                    chars = "\\u007F";
                    key = "Back";

                }


                {
                    chars = "\\u001B\u007F";
                    key = "Back";
                    mods = "Alt";
                }


                {
                    chars = "\\u001B[2~";
                    key = "Insert";

                }


                {
                    chars = "\\u001B[3~";
                    key = "Delete";

                }


                {
                    chars = "\\u0002&";
                    key = "W";
                    mods = "Command";
                }


                {
                    chars = "\\u0002c";
                    key = "T";
                    mods = "Command";
                }


                {
                    chars = "\\u0002n";
                    key = "RBracket";
                    mods = "Command|Shift";
                }


                {
                    chars = "\\u0002p";
                    key = "LBracket";
                    mods = "Command|Shift";
                }


                {
                    chars = "\\u0002o";
                    key = "RBracket";
                    mods = "Command";
                }


                {
                    chars = "\\u0002;";
                    key = "LBracket";
                    mods = "Command";
                }


                {
                    chars = "\\u0002/";
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
                opacity = 0.95;

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

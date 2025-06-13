{config, ...}: let
  plug_bar =
    /*
    kdl
    */
    ''
      default_tab_template {
          pane size=1 borderless=true {
              plugin location="https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm"{
                  format_left   "{mode} #[fg=#89B4FA,bold]{session}"
                  format_center "{tabs}"
                  format_right  "{command_git_name}{command_git_branch}{command_git_files}{command_git_add}{command_git_sub}{datetime}"
                  format_space  ""

                  border_enabled  "false"
                  border_char     "─"
                  border_format   "#[fg=#6C7086]{char}"
                  border_position "top"

                  hide_frame_for_single_pane "false"

                  mode_normal  "#[bg=#cba6f7,fg=black,bold]Session:"
                  mode_locked  "#[bg=#cba6f7,fg=black,bold]Session Locked:"
                  mode_tmux    "#[bg=#ffc387,fg=black,bold]Session:"

                  tab_normal   "#[fg=#D2F7A6] {name} "
                  tab_active   "#[fg=#cba6f7,bold,italic] {name} "

                  command_git_branch_command     "bash -c 'gitstatus --branch |xargs'"
                  command_git_branch_format      "#[fg=#cba6f7] {stdout} "
                  command_git_branch_interval    "10"
                  command_git_branch_rendermode  "static"

                  command_git_files_command     "bash -c 'gitstatus --files |xargs'"
                  command_git_files_format      "#[fg=#ffc387] {stdout} "
                  command_git_files_interval    "10"
                  command_git_files_rendermode  "static"

                  command_git_add_command     "bash -c 'gitstatus --add |xargs'"
                  command_git_add_format      "#[fg=green] {stdout} "
                  command_git_add_interval    "10"
                  command_git_add_rendermode  "static"

                  command_git_sub_command     "bash -c 'gitstatus --sub |xargs'"
                  command_git_sub_format      "#[fg=red] {stdout} "
                  command_git_sub_interval    "10"
                  command_git_sub_rendermode  "static"

                  command_git_name_command     "bash -c 'gitstatus --name |xargs'"
                  command_git_name_format      "#[fg=#cba6f7] {stdout} "
                  command_git_name_interval    "10"
                  command_git_name_rendermode  "static"

                  datetime        "#[fg=#df5b61,bold] {format} "
                  datetime_format "%A, %d %b %Y %H:%M"
                  datetime_timezone "America/New_York"
              }
          }
          children
      }
    '';
in {
  programs.zellij = {
    enable = false;
  };
  home.file."${config.xdg.configHome}/zellij/config.kdl".text =
    /*
    kdl
    */
    ''
      default_shell "nu"
      keybinds {
          normal {
              bind "Enter" {  // Intercept `Enter`.
                  WriteChars "\u{000D}";  // Passthru `Enter`.
              }
          }
          shared{
            bind "Alt f" {
                SwitchToMode "Normal"
                    ToggleFocusFullscreen
            }
            bind "Alt d" {
                SwitchToMode "Normal"
                    Detach
            }
        }
        locked {
                bind "Ctrl g" { SwitchToMode "Normal"; }
        }
        resize {
                bind "Ctrl n" { SwitchToMode "Normal"; }
                bind "h" "Left" { Resize "Increase Left"; }
                bind "j" "Down" { Resize "Increase Down"; }
                bind "k" "Up" { Resize "Increase Up"; }
                bind "l" "Right" { Resize "Increase Right"; }
                bind "H" { Resize "Decrease Left"; }
                bind "J" { Resize "Decrease Down"; }
                bind "K" { Resize "Decrease Up"; }
                bind "L" { Resize "Decrease Right"; }
                bind "=" "+" { Resize "Increase"; }
                bind "-" { Resize "Decrease"; }
            }
            pane {
                bind "Ctrl p" { SwitchToMode "Normal"; }
                bind "h" "Left" { MoveFocus "Left"; }
                bind "l" "Right" { MoveFocus "Right"; }
                bind "j" "Down" { MoveFocus "Down"; }
                bind "k" "Up" { MoveFocus "Up"; }
                bind "p" { SwitchFocus; }
                bind "n" { NewPane; SwitchToMode "Normal"; }
                bind "d" { NewPane "Down"; SwitchToMode "Normal"; }
                bind "r" { NewPane "Right"; SwitchToMode "Normal"; }
                bind "x" { CloseFocus; SwitchToMode "Normal"; }
                bind "f" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
                bind "z" { TogglePaneFrames; SwitchToMode "Normal"; }
                bind "w" { ToggleFloatingPanes; SwitchToMode "Normal"; }
                bind "e" { TogglePaneEmbedOrFloating; SwitchToMode "Normal"; }
                bind "c" { SwitchToMode "RenamePane"; PaneNameInput 0;}
            }
            move {
                bind "Ctrl h" { SwitchToMode "Normal"; }
                bind "n" "Tab" { MovePane; }
                bind "p" { MovePaneBackwards; }
                bind "h" "Left" { MovePane "Left"; }
                bind "j" "Down" { MovePane "Down"; }
                bind "k" "Up" { MovePane "Up"; }
                bind "l" "Right" { MovePane "Right"; }
            }
            tab {
                bind "Ctrl t" { SwitchToMode "Normal"; }
                bind "r" { SwitchToMode "RenameTab"; TabNameInput 0; }
                bind "h" "Left" "Up" "k" { GoToPreviousTab; }
                bind "l" "Right" "Down" "j" { GoToNextTab; }
                bind "n" { NewTab; SwitchToMode "Normal"; }
                bind "x" { CloseTab; SwitchToMode "Normal"; }
                bind "s" { ToggleActiveSyncTab; SwitchToMode "Normal"; }
                bind "b" { BreakPane; SwitchToMode "Normal"; }
                bind "]" { BreakPaneRight; SwitchToMode "Normal"; }
                bind "[" { BreakPaneLeft; SwitchToMode "Normal"; }
                bind "1" { GoToTab 1; SwitchToMode "Normal"; }
                bind "2" { GoToTab 2; SwitchToMode "Normal"; }
                bind "3" { GoToTab 3; SwitchToMode "Normal"; }
                bind "4" { GoToTab 4; SwitchToMode "Normal"; }
                bind "5" { GoToTab 5; SwitchToMode "Normal"; }
                bind "6" { GoToTab 6; SwitchToMode "Normal"; }
                bind "7" { GoToTab 7; SwitchToMode "Normal"; }
                bind "8" { GoToTab 8; SwitchToMode "Normal"; }
                bind "9" { GoToTab 9; SwitchToMode "Normal"; }
                bind "Tab" { ToggleTab; }
            }
            scroll {
                bind "Ctrl s" { SwitchToMode "Normal"; }
                bind "e" { EditScrollback; SwitchToMode "Normal"; }
                bind "s" { SwitchToMode "EnterSearch"; SearchInput 0; }
                bind "Ctrl c" { ScrollToBottom; SwitchToMode "Normal"; }
                bind "j" "Down" { ScrollDown; }
                bind "k" "Up" { ScrollUp; }
                bind "Ctrl f" "PageDown" "Right" "l" { PageScrollDown; }
                bind "Ctrl b" "PageUp" "Left" "h" { PageScrollUp; }
                bind "d" { HalfPageScrollDown; }
                bind "u" { HalfPageScrollUp; }
                // uncomment this and adjust key if using copy_on_select=false
                // bind "Alt c" { Copy; }
            }
            search {
                bind "Ctrl s" { SwitchToMode "Normal"; }
                bind "Ctrl c" { ScrollToBottom; SwitchToMode "Normal"; }
                bind "j" "Down" { ScrollDown; }
                bind "k" "Up" { ScrollUp; }
                bind "Ctrl f" "PageDown" "Right" "l" { PageScrollDown; }
                bind "Ctrl b" "PageUp" "Left" "h" { PageScrollUp; }
                bind "d" { HalfPageScrollDown; }
                bind "u" { HalfPageScrollUp; }
                bind "n" { Search "down"; }
                bind "p" { Search "up"; }
                bind "c" { SearchToggleOption "CaseSensitivity"; }
                bind "w" { SearchToggleOption "Wrap"; }
                bind "o" { SearchToggleOption "WholeWord"; }
            }
            entersearch {
                bind "Ctrl c" "Esc" { SwitchToMode "Scroll"; }
                bind "Enter" { SwitchToMode "Search"; }
            }
            renametab {
                bind "Ctrl c" { SwitchToMode "Normal"; }
                bind "Esc" { UndoRenameTab; SwitchToMode "Tab"; }
            }
            renamepane {
                bind "Ctrl c" { SwitchToMode "Normal"; }
                bind "Esc" { UndoRenamePane; SwitchToMode "Pane"; }
            }
            session {
                bind "Ctrl o" { SwitchToMode "Normal"; }
                bind "Ctrl s" { SwitchToMode "Scroll"; }
                bind "d" { Detach; }
                bind "w" {
                    LaunchOrFocusPlugin "session-manager" {
                        floating true
                        move_to_focused_tab true
                    };
                    SwitchToMode "Normal"
                }
                bind "c" {
                    LaunchOrFocusPlugin "configuration" {
                        floating true
                        move_to_focused_tab true
                    };
                    SwitchToMode "Normal"
                }
                bind "p" {
                    LaunchOrFocusPlugin "plugin-manager" {
                        floating true
                        move_to_focused_tab true
                    };
                    SwitchToMode "Normal"
                }
                bind "a" {
                    LaunchOrFocusPlugin "zellij:about" {
                        floating true
                        move_to_focused_tab true
                    };
                    SwitchToMode "Normal"
                }
            }
      }
      plugins {
          "filepicker"
          "tab-bar"
          "status-bar"
          "strider"
          "compact-bar"
          "session-manager"
          //...
      }
      theme "kanagawabones"
    '';
  home.file."${config.xdg.configHome}/zellij/layouts/default.kdl".text =
    /*
    kdl
    */
    ''
      layout {
          tab name="Main" focus=true hide_floating_panes=true {
              pane split_direction="vertical" {
                  pane command="nvim" size="60%" {
                  }
                  pane size="40%" {
                      pane  focus=true size="50%"
                      pane command="yazi" size="50%" cwd="/home/salhashemi2/" {
                      }
                  }
              }
          }
          tab name="Spotify" hide_floating_panes=true {
              pane command="zsh"
              floating_panes {
                pane command="spotify_player" {
                    height 35
                    width 175
                    x 19
                    y 6
                }
            }
          }
          ${plug_bar}
      }
    '';
  home.file."${config.xdg.configHome}/zellij/layouts/rust.kdl".text =
    /*
    kdl
    */
    ''

      layout {
          tab name="Rust Dev" focus=true hide_floating_panes=true {
              pane split_direction="vertical" focus=true {
                  pane command="rust4zellij" size="60%"
                  pane size="40%" {
                      pane command="nix" size="50%" {
                          args "develop" "-c" "bacon" "test"
                      }
                      pane command="nix" size="50%" {
                          args "develop" "-c" "bacon" "clippy-all"
                      }
                  }
              }
          }
          tab name="Scratchpad" hide_floating_panes=true {
              pane command="nix" {
                  args "develop" "-c" "nu"
              }
          }
          ${plug_bar}
      }
    '';
}

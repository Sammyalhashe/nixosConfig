{ pkgs }:

pkgs.writeShellScriptBin "hgrep" ''
  HISTFILE=~/.zsh_history
  set -o history
  history | grep $1
''

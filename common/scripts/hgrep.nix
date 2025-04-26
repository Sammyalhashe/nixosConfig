{ pkgs }:

pkgs.writeShellScriptBin "hgrep" ''
    history | grep $1
''

{ pkgs }:

pkgs.writeShellScriptBin "system-copy" ''
  if command -v wl-copy > /dev/null; then
    wl-copy
  elif command -v clip.exe > /dev/null; then
    clip.exe
  elif command -v pbcopy > /dev/null; then
    pbcopy
  elif command -v xclip > /dev/null; then
    xclip -selection clipboard
  else
    # fallback to just printing if no clipboard is found, or maybe error out
    cat
  fi
''

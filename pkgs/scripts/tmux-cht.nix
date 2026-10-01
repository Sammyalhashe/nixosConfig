{ pkgs }:

pkgs.writeShellScriptBin "tmux-cht" ''
  if [[ -z $CHT_HOME ]]; then
      CHT_HOME="$HOME/.dotfiles/self_scripts"
  fi
  selected=`cat $CHT_HOME/.tmux-cht-languages $CHT_HOME/.tmux-cht-command | fzf`
  if [[ -z $selected ]]; then
      exit 0
  fi

  read -p "Enter Query: " query

  # remove the hook to ask us the name of the new window
  ${pkgs.tmux}/bin/tmux set-hook -gu after-new-window

  query=`echo $query | tr ' ' '+'`
  if grep -qs "$selected" $CHT_HOME/.tmux-cht-languages; then
      ${pkgs.tmux}/bin/tmux neww bash -c "curl -s cht.sh/$selected/$query | less"
  else
      ${pkgs.tmux}/bin/tmux neww bash -c "curl -s cht.sh/$selected~$query | less"
  fi

  # add the hook back (this is defined in my ~/.tmux.conf)
  ${pkgs.tmux}/bin/tmux set-hook -g after-new-window "command-prompt -I '#{window_name}' 'rename-window \"%%\"'"
''

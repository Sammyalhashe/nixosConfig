{ pkgs }:

pkgs.writeShellScriptBin "fzf-man" ''
    # set colours in man pages
    export LESS_TERMCAP_mb=$'\e[1;32m'
    export LESS_TERMCAP_md=$'\e[1;32m'
    export LESS_TERMCAP_me=$'\e[0m'
    export LESS_TERMCAP_se=$'\e[0m'
    export LESS_TERMCAP_so=$'\e[01;33m'
    export LESS_TERMCAP_ue=$'\e[0m'
    export LESS_TERMCAP_us=$'\e[1;4;31m'

    # process all man pages
    selected_manpage=`find /usr/share/man/**/* | awk -F\/ '{ print $NF }'| ${pkgs.fzf}/bin/fzf | awk -F\. '{ for(i=1; i<NF;i++) {if(i!=1){out=out"."} out=out$i}; print out}'`

    # run selected man command
    man $selected_manpage
''

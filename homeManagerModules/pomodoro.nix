{ pkgs, ... }:
let
  pomo = pkgs.writeShellScriptBin "pomo" ''
    #!/usr/bin/env bash

    # Check for tput and clear
    if ! command -v tput &> /dev/null; then
        echo "tput not found. Please install ncurses."
        exit 1
    fi

    cleanup() {
      tput cnorm
      echo
      exit 0
    }
    trap cleanup SIGINT

    DURATION="25"
    if [ -n "$1" ]; then
      DURATION="$1"
    else
      echo "Enter duration in minutes (default 25):"
      read -t 10 input
      if [ -n "$input" ]; then
        DURATION="$input"
      fi
    fi

    # Check if input is a number
    if ! [[ "$DURATION" =~ ^[0-9]+$ ]]; then
        echo "Invalid duration. Using 25."
        DURATION=25
    fi

    SECONDS=$((DURATION * 60))
    START=$(date +%s)
    END=$((START + SECONDS))

    tput civis
    clear
    echo "Starting Pomodoro for $DURATION minutes..."

    while [ $(date +%s) -lt $END ]; do
        NOW=$(date +%s)
        LEFT=$((END - NOW))
        MIN=$((LEFT / 60))
        SEC=$((LEFT % 60))
        printf "\rTime left: %02d:%02d" $MIN $SEC
        sleep 1
    done

    echo
    echo "Time is up!"
    if command -v notify-send >/dev/null; then
        notify-send "Pomodoro" "Time is up! Take a break."
    else
        echo -e "\a"
    fi
    tput cnorm

    echo "Press any key to close..."
    read -n 1 -s
  '';
in
{
  home.packages = [
    pomo
    pkgs.libnotify
    pkgs.ncurses
  ];
}

#!/usr/bin/env bash
SESSION_ICON=$'\uF2D2'
session=$(tmux display-message -p '#S')
printf "#[fg=colour76,bg=colour236] ${SESSION_ICON} ${session} #[fg=colour236,bg=default]"

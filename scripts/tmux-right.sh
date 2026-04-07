#!/usr/bin/env bash
# Renders session block for tmux status-right
SESSION_ICON=$'\uF2D2'
session=$(tmux display-message -p '#S')
printf "#[fg=colour76,bg=colour236] ${SESSION_ICON} ${session} "

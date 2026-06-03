#!/usr/bin/env bash
SESSION_ICON=$(printf '\357\213\222')
session=$(tmux display-message -p '#S')
printf "#[fg=colour76,bg=colour236] %s %s #[fg=colour236,bg=default]" "$SESSION_ICON" "$session"

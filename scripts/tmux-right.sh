#!/usr/bin/env bash
# Renders windows + session for tmux status-right
BG=colour234
SESSION_ICON=$'\uF2D2'

current_window=$(tmux display-message -p '#I')
output=""

for win in $(tmux list-windows -F '#I:#W'); do
  idx="${win%%:*}"
  name="${win#*:}"
  if [[ "$idx" == "$current_window" ]]; then
    output+="#[fg=colour39,bg=colour236] ${idx}:${name} #[bg=${BG}] "
  else
    output+="#[fg=colour240,bg=colour235] ${idx}:${name} #[bg=${BG}] "
  fi
done

session=$(tmux display-message -p '#S')
output+="#[fg=colour76,bg=colour236] ${SESSION_ICON} ${session} "

printf "%s" "$output"

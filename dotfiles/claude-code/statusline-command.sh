#!/bin/bash

# Read JSON input from stdin
INPUT=$(cat)
echo "$INPUT" > ~/tmp/status.json
MODEL_RAW=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"')
case "$MODEL_RAW" in
  *opus*|*Opus*) MODEL="opus" ;;
  *sonnet*|*Sonnet*) MODEL="sonnet" ;;
  *haiku*|*Haiku*) MODEL="haiku" ;;
  *) MODEL="$MODEL_RAW" ;;
esac
CWD=$(echo "$INPUT" | jq -r '.workspace.current_dir // .cwd')
DIR=$(echo "$CWD" | sed "s|^$HOME|~|")
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0' | awk '{printf "%.2f", $1}')
CTX_REMAINING=$(echo "$INPUT" | jq -r '.context_window.remaining_percentage // 100')

# Get git branch
BRANCH=$(cd "$CWD" 2>/dev/null && git branch --show-current 2>/dev/null)

# Color-code context remaining (green >50%, yellow 20-50%, red <20%)
if [ "$CTX_REMAINING" -gt 50 ]; then
  CTX_COLOR="\033[32m"  # Green
elif [ "$CTX_REMAINING" -gt 20 ]; then
  CTX_COLOR="\033[33m"  # Yellow
else
  CTX_COLOR="\033[31m"  # Red
fi

# Build statusline
printf "\033[36m$DIR\033[0m"
[ -n "$BRANCH" ] && printf " on \033[33m⎇ $BRANCH\033[0m"
printf " using \033[1m$MODEL\033[0m"
printf " ${CTX_COLOR}[${CTX_REMAINING}%% left]\033[0m"
printf " \033[93m\$${COST}\033[0m"

echo

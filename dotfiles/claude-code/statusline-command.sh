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

# Get git info
if cd "$CWD" 2>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null; then
  BRANCH=$(git branch --show-current 2>/dev/null)

  # Ahead/behind remote
  AHEAD=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo 0)
  BEHIND=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)

  # Stash count
  STASH=$(git stash list 2>/dev/null | wc -l | tr -d ' ')

  # Use git status --porcelain for staged/unstaged/untracked/conflicted
  GIT_STATUS=$(git status --porcelain 2>/dev/null)
  STAGED=$(echo "$GIT_STATUS" | grep -c '^[MADRC]' 2>/dev/null || echo 0)
  UNSTAGED=$(echo "$GIT_STATUS" | grep -c '^.[MD]' 2>/dev/null || echo 0)
  UNTRACKED=$(echo "$GIT_STATUS" | grep -c '^??' 2>/dev/null || echo 0)
  CONFLICTS=$(echo "$GIT_STATUS" | grep -c '^UU\|^AA\|^DD' 2>/dev/null || echo 0)
fi

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
if [ -n "$BRANCH" ]; then
  printf " on \033[33m⎇ $BRANCH\033[0m"
  # p10k-style git status indicators
  [ "$BEHIND" -gt 0 ] 2>/dev/null && printf "\033[36m⇣$BEHIND\033[0m"
  [ "$AHEAD" -gt 0 ] 2>/dev/null && printf "\033[36m⇡$AHEAD\033[0m"
  [ "$STASH" -gt 0 ] 2>/dev/null && printf "\033[35m*$STASH\033[0m"
  [ "$CONFLICTS" -gt 0 ] 2>/dev/null && printf "\033[31m~$CONFLICTS\033[0m"
  [ "$STAGED" -gt 0 ] 2>/dev/null && printf "\033[32m+$STAGED\033[0m"
  [ "$UNSTAGED" -gt 0 ] 2>/dev/null && printf "\033[33m!$UNSTAGED\033[0m"
  [ "$UNTRACKED" -gt 0 ] 2>/dev/null && printf "\033[34m?$UNTRACKED\033[0m"
fi
printf " using \033[1m$MODEL\033[0m"
printf " ${CTX_COLOR}[${CTX_REMAINING}%% left]\033[0m"
printf " \033[93m\$${COST}\033[0m"

echo

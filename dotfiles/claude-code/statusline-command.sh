#!/usr/bin/env bash

# prevent stale index.lock files. Blocks claude's commits https://github.com/anthropics/claude-code/issues/11005
GIT_OPTIONAL_LOCKS=0

ICON_FOLDER=$'\xF3\xB0\x9D\xB0'
ICON_BRANCH=$'\xF3\xB0\x98\xAC'
ICON_ROBOT=$'\U0000EE0D'
ICON_CASH=$'\xF3\xB0\x84\x94'
ICON_INVOICE=$'\xF3\xB1\x89\x9F'
ICON_CAL_RANGE=$'\xF3\xB0\x83\xB0'
ICON_CAL_TODAY=$'\xF3\xB0\xB8\x97'
ICON_TIMER=$'\xF3\xB1\x8E\xAB'
ICON_DUMB=$'\U000F002A'
ICON_DEATH=$'\U000F0238'
ICON_SKULL=$'\U0000EF0E'

# Read JSON input from stdin
INPUT=$(cat)
echo "$INPUT" > ~/tmp/status.json

MODEL=""
MODEL_ID=""
CLOUD=""
CLOUD_COLOR=""
if [ -n "$ANTHROPIC_BASE_URL" ] && [[ "$ANTHROPIC_BASE_URL" != *"anthropic.com"* ]]; then
  MODELS_JSON=$(curl -sf --max-time 1 "$ANTHROPIC_BASE_URL/v1/models" 2>/dev/null)
  if [ -n "$MODELS_JSON" ]; then
    MODEL_ID=$(echo "$MODELS_JSON" | jq -r '.data[0].id // empty' 2>/dev/null)
    if [ -n "$MODEL_ID" ]; then
      FAMILY=$(echo "$MODEL_ID" | sed -E 's|.*/||; s/[-_][0-9].*//' | tr '[:upper:]' '[:lower:]' | tr -d '-')
      SIZE=$(echo "$MODEL_ID" | grep -oiE '[Ee][0-9]+[Bb]|[0-9]+[Bb][-_]?[Aa][0-9]+[Bb]|[0-9]+[Bb]' | head -1 | tr '[:upper:]' '[:lower:]')
      QUANT=$(echo "$MODEL_ID" | grep -oiE '[Qq][0-9]+_[0-9]+|[Qq][0-9]+[Kk]_[A-Za-z]+' | head -1 | tr '[:upper:]' '[:lower:]')
      MODEL="${FAMILY}"
      [ -n "$SIZE" ] && MODEL="${MODEL}-${SIZE}"
      [ -n "$QUANT" ] && MODEL="${MODEL} ${QUANT}"
    fi
  fi
  case "$MODEL_ID" in
    *gemma*|*Gemma*)   CLOUD=$'\xEE\x9F\xB0'; CLOUD_COLOR="\033[38;5;33m" ;;
    *)                 CLOUD=$'\xEE\xB9\x8B'; CLOUD_COLOR="\033[38;5;118m" ;;
  esac
  {
    echo "ANTHROPIC_BASE_URL=$ANTHROPIC_BASE_URL"
    echo "MODEL_ID=$MODEL_ID"
    echo "FAMILY=$FAMILY"
    echo "SIZE=$SIZE"
    echo "QUANT=$QUANT"
    echo "MODEL=$MODEL"
    echo "MODELS_JSON=$MODELS_JSON"
  } > ~/tmp/status-model-debug.txt
elif [ "$CLAUDE_CODE_USE_FOUNDRY" = "1" ]; then
  CLOUD=$'\xEE\xAF\x98'
  CLOUD_COLOR="\033[94m"
elif [ "$CLAUDE_CODE_USE_BEDROCK" = "1" ]; then
  CLOUD=$'\xEF\x89\xB0'
  CLOUD_COLOR="\033[38;5;208m"
else
  CLOUD=$'\xF3\xB0\xA8\xB9'
  CLOUD_COLOR="\033[38;5;245m"
fi
if [ -z "$MODEL" ]; then
  MODEL_ID_IN=$(echo "$INPUT" | jq -r '.model.id // empty')
  if [ -n "$MODEL_ID_IN" ]; then
    MODEL=$(echo "$MODEL_ID_IN" | sed -E '
      s|^global\.anthropic\.||;
      s|^claude-||;
      s|-v[0-9]+||;
      s|^([a-z]+)-([0-9]+)-([0-9]+)|\1 \2.\3|
    ')
  else
    MODEL_RAW=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"')
    case "$MODEL_RAW" in
      *opus*|*Opus*)     MODEL="opus" ;;
      *sonnet*|*Sonnet*) MODEL="sonnet" ;;
      *haiku*|*Haiku*)   MODEL="haiku" ;;
      *)                 MODEL="$MODEL_RAW" ;;
    esac
  fi
fi
CWD=$(echo "$INPUT" | jq -r '.workspace.current_dir // .cwd')
DIR=$(echo "$CWD" | sed "s|^$HOME|~|")
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0' | awk '{printf "%.0f", $1}')
DURATION_MS=$(echo "$INPUT" | jq -r '.cost.total_duration_ms // 0')
DURATION_SEC=$((DURATION_MS / 1000))
DAYS=$((DURATION_SEC / 86400))
HOURS=$(( (DURATION_SEC % 86400) / 3600 ))
MINS=$(( (DURATION_SEC % 3600) / 60 ))
SECS=$((DURATION_SEC % 60))
CTX_PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
CTX_TOKENS=$(echo "$INPUT" | jq -r '[.context_window.current_usage.input_tokens, .context_window.current_usage.cache_creation_input_tokens, .context_window.current_usage.cache_read_input_tokens] | map(. // 0) | add')
CTX_TOKENS_K=$(awk -v t="$CTX_TOKENS" 'BEGIN { printf "%dk", (t + 500) / 1000 }')
COMPACT_PCT=${CLAUDE_AUTOCOMPACT_PCT_OVERRIDE:-96.7}
CTX_USABLE=$(echo "$CTX_PCT" | awk -v cap="$COMPACT_PCT" '{v = $1 * 100 / cap; printf "%.0f", (v > 100 ? 100 : v)}')

# Get git info
if cd "$CWD" 2>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null; then
  GIT_EMAIL=$(git config user.email 2>/dev/null)
  case "$GIT_EMAIL" in
    jim.weller@gmail.com) GIT_USER="jw";   GIT_USER_ICON=$'\xEF\x8A\xBB'; GIT_USER_COLOR="\033[38;5;33m" ;;
    jim.weller@mcg.com)   GIT_USER="work"; GIT_USER_ICON=$'\xEF\x91\xAE'; GIT_USER_COLOR="\033[38;5;196m" ;;
    "")                   GIT_USER="" ;;
    *)                    GIT_USER="$GIT_EMAIL"; GIT_USER_ICON=$'\xEF\x8A\xBB'; GIT_USER_COLOR="\033[38;5;29m" ;;
  esac

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

if [ "$CTX_USABLE" -gt 90 ]; then
  CTX_COLOR="\033[38;5;124m"
  CTX_ICON=$ICON_SKULL
elif [ "$CTX_USABLE" -ge 80 ]; then
  CTX_COLOR="\033[38;5;202m"
  CTX_ICON=$ICON_DEATH
elif [ "$CTX_USABLE" -ge 70 ]; then
  CTX_COLOR="\033[38;5;220m"
  CTX_ICON=$ICON_DUMB
else
  CTX_COLOR="\033[38;5;67m"
  CTX_ICON=$ICON_ROBOT
fi

BAR_WIDTH=12
BUFFER_WIDTH=2
FILLED=$((CTX_USABLE * BAR_WIDTH / 100))
REMAINING=$((BAR_WIDTH - FILLED))
if [ "$REMAINING" -lt "$BUFFER_WIDTH" ]; then
  BUFFER_SHOW=$REMAINING
else
  BUFFER_SHOW=$BUFFER_WIDTH
fi
EMPTY=$((REMAINING - BUFFER_SHOW))
BAR_FILLED=""
BAR_EMPTY=""
BAR_BUFFER=""
[ "$FILLED" -gt 0 ] && BAR_FILLED=$(printf "%${FILLED}s" | tr ' ' '█')
[ "$EMPTY" -gt 0 ] && BAR_EMPTY=$(printf "%${EMPTY}s" | tr ' ' '█')
[ "$BUFFER_SHOW" -gt 0 ] && BAR_BUFFER=$(printf "%${BUFFER_SHOW}s" | tr ' ' '░')

# Build statusline
[ -n "$CLOUD" ] && printf "${CLOUD_COLOR}${CLOUD}\033[0m | "
printf "\033[38;5;117m${ICON_FOLDER} $DIR\033[0m"
[ -n "$GIT_USER" ] && printf " | ${GIT_USER_COLOR}${GIT_USER_ICON} $GIT_USER\033[0m"
if [ -n "$BRANCH" ]; then
  printf " | \033[33m${ICON_BRANCH} $BRANCH\033[0m"
  [ "$BEHIND" -gt 0 ] 2>/dev/null && printf " \033[96m⇣$BEHIND\033[0m"
  [ "$AHEAD" -gt 0 ] 2>/dev/null && printf " \033[96m⇡$AHEAD\033[0m"
  [ "$STASH" -gt 0 ] 2>/dev/null && printf " \033[95m*$STASH\033[0m"
  [ "$CONFLICTS" -gt 0 ] 2>/dev/null && printf " \033[91m~$CONFLICTS\033[0m"
  [ "$STAGED" -gt 0 ] 2>/dev/null && printf " \033[92m+$STAGED\033[0m"
  [ "$UNSTAGED" -gt 0 ] 2>/dev/null && printf " \033[93m!$UNSTAGED\033[0m"
  [ "$UNTRACKED" -gt 0 ] 2>/dev/null && printf " \033[97m?$UNTRACKED\033[0m"
fi
printf " | ${CTX_COLOR}${CTX_ICON}  $MODEL\033[0m"
printf " ${CTX_COLOR}${BAR_FILLED}\033[38;5;240m${BAR_EMPTY}\033[0m\033[38;5;250m${BAR_BUFFER}\033[0m ${CTX_COLOR}${CTX_USABLE}%% ${CTX_TOKENS_K}\033[0m"
PROJECT_KEY=$(echo "$INPUT" | jq -r '.workspace.project_dir // "" | gsub("[/.]"; "-") | gsub("_"; "")')
CCUSAGE_CACHE="/tmp/ccusage-cache.json"
AZURE_CACHE="/tmp/azure-cost-cache.json"
COST_PROJECT=""
COST_MONTH=""
COST_MTD=""
if [ -f "$CCUSAGE_CACHE" ] && [ -n "$PROJECT_KEY" ]; then
  COST_PROJECT=$(jq -r --arg p "$PROJECT_KEY" '[.projects[$p][]? | .totalCost] | add // empty' "$CCUSAGE_CACHE" 2>/dev/null | awk '{printf "%.0f", $1}')
fi
if [ -f "$AZURE_CACHE" ]; then
  COST_MTD=$(jq -r '.mtd // empty' "$AZURE_CACHE" 2>/dev/null | awk '{printf "%.0f", $1}')
  COST_MONTH=$(jq -r '.rolling30d // empty' "$AZURE_CACHE" 2>/dev/null | awk '{printf "%.0f", $1}')
fi
fmtc() { LC_ALL=en_US.UTF-8 printf "%'d" "${1:-0}" 2>/dev/null || echo "${1:-0}"; }
COST=$(fmtc "$COST")
[ -n "$COST_PROJECT" ] && COST_PROJECT=$(fmtc "$COST_PROJECT")
[ -n "$COST_MTD" ] && COST_MTD=$(fmtc "$COST_MTD")
[ -n "$COST_MONTH" ] && COST_MONTH=$(fmtc "$COST_MONTH")
printf " | \033[38;5;186m${ICON_CASH} \$${COST}\033[0m"
[ -n "$COST_PROJECT" ] && printf " \033[38;5;186m${ICON_INVOICE} \$${COST_PROJECT}\033[0m"
[ -n "$COST_MTD" ] && printf " \033[38;5;186m${ICON_CAL_TODAY} \$${COST_MTD}\033[0m"
[ -n "$COST_MONTH" ] && printf " \033[38;5;186m${ICON_CAL_RANGE} \$${COST_MONTH}\033[0m"
if [ "$DAYS" -gt 0 ]; then
  DURATION="${DAYS}d ${HOURS}h ${MINS}m ${SECS}s"
elif [ "$HOURS" -gt 0 ]; then
  DURATION="${HOURS}h ${MINS}m ${SECS}s"
elif [ "$MINS" -gt 0 ]; then
  DURATION="${MINS}m ${SECS}s"
else
  DURATION="${SECS}s"
fi
printf " | \033[38;5;250m${ICON_TIMER} ${DURATION}\033[0m"

echo

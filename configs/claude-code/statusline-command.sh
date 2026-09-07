#!/usr/bin/env bash

# prevent stale index.lock files. Blocks claude's commits https://github.com/anthropics/claude-code/issues/11005
GIT_OPTIONAL_LOCKS=0

ICON_FOLDER=$'\xF3\xB0\x9D\xB0'
ICON_BRANCH=$'\xF3\xB0\x98\xAC'
ICON_ROBOT=$'\U0000EE0D'
ICON_CASH=$'\xF3\xB0\x84\x94'
ICON_INVOICE=$'\xF3\xB1\x89\x9F'
ICON_DIVISION=$'\xF3\xB0\x87\x94'
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

EFFORT_LEVEL=$(echo "$INPUT" | jq -r '.effort.level // empty')
# Luminance ramp rather than a hue ramp: the operator's CVD type is unknown, and
# brightness is the one channel every dichromacy preserves. The letter carries the
# level on its own, so color is reinforcement. Medium and max both render m by
# request; their brightness is what separates them.
case "$EFFORT_LEVEL" in
  low)    EFFORT_TEXT="l"; EFFORT_COLOR="\033[38;5;240m" ;;
  medium) EFFORT_TEXT="m"; EFFORT_COLOR="\033[38;5;244m" ;;
  high)   EFFORT_TEXT="h"; EFFORT_COLOR="\033[38;5;249m" ;;
  xhigh)  EFFORT_TEXT="x"; EFFORT_COLOR="\033[38;5;253m" ;;
  max)    EFFORT_TEXT="m"; EFFORT_COLOR="\033[1;38;5;231m" ;;
  ultra*) EFFORT_TEXT="u"; EFFORT_COLOR="\033[1;7;38;5;231m" ;;
  *)      EFFORT_TEXT="l"; EFFORT_COLOR="\033[38;5;240m" ;;
esac

CWD=$(echo "$INPUT" | jq -r '.workspace.current_dir // .cwd')
DIR=$(echo "$CWD" | sed "s|^$HOME|~|")
COST_RAW=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')
COST=$(printf '%s' "$COST_RAW" | awk '{printf "%.0f", $1}')
DURATION_MS=$(echo "$INPUT" | jq -r '.cost.total_duration_ms // 0')
DURATION_SEC=$((DURATION_MS / 1000))
DAYS=$((DURATION_SEC / 86400))
HOURS=$(( (DURATION_SEC % 86400) / 3600 ))
MINS=$(( (DURATION_SEC % 3600) / 60 ))
CTX_TOKENS=$(echo "$INPUT" | jq -r '[.context_window.current_usage.input_tokens, .context_window.current_usage.cache_creation_input_tokens, .context_window.current_usage.cache_read_input_tokens] | map(. // 0) | add')
CTX_TOKENS_K=$(awk -v t="$CTX_TOKENS" 'BEGIN { printf "%dk", (t + 500) / 1000 }')
# Autocompaction fires at a fixed token count, not a share of the model window.
# used_percentage is measured against the real 1M window, so it reads 40% at the cap.
COMPACT_THRESHOLD=400000
CTX_USABLE=$(awk -v t="$CTX_TOKENS" -v cap="$COMPACT_THRESHOLD" 'BEGIN { v = t * 100 / cap; printf "%.0f", (v > 100 ? 100 : v) }')

# Get git info. GIT_USER and GIT_EMAIL are also exported by the git profile secrets,
# so they are cleared first to keep the environment from leaking into the segment.
GIT_USER=""
GIT_USER_ICON=""
GIT_USER_COLOR=""
BRANCH=""
if cd "$CWD" 2>/dev/null; then
  # Resolve the git profile. The work and hearst profiles share an email, so the address
  # alone cannot separate them, and GIT_CONFIG_GLOBAL is frozen at whatever the launching
  # shell exported and never sees a mid-session switch. $CWD arrives fresh on every
  # invocation, so the profile tree wins, matching mise's trusted_config_paths.
  GIT_PROFILE=""
  case "${CWD#$HOME/}" in
    hearst|hearst/*)     GIT_PROFILE="hearst" ;;
    work|work/*)         GIT_PROFILE="work" ;;
    personal|personal/*) GIT_PROFILE="jim" ;;
    *)                   GIT_PROFILE="${GIT_CONFIG_GLOBAL##*/.gitconfig-}" ;;
  esac
  [ "$GIT_PROFILE" = "$GIT_CONFIG_GLOBAL" ] && GIT_PROFILE=""

  # Read the identity outside the work-tree check so it matches the zsh prompt in non-repo dirs
  GIT_EMAIL=$(git config user.email 2>/dev/null)
  case "$GIT_PROFILE" in
    jim)    GIT_USER="jw";     GIT_USER_ICON=$'\xEF\x8A\xBB'; GIT_USER_COLOR="\033[38;5;33m" ;;
    work)   GIT_USER="work";   GIT_USER_ICON=$'\xEF\x91\xAE'; GIT_USER_COLOR="\033[38;5;196m" ;;
    hearst) GIT_USER="hearst"; GIT_USER_ICON=$'\xEF\x82\x9B'; GIT_USER_COLOR="\033[38;5;208m" ;;
    *)
      case "$GIT_EMAIL" in
        jim.weller@gmail.com) GIT_USER="jw";   GIT_USER_ICON=$'\xEF\x8A\xBB'; GIT_USER_COLOR="\033[38;5;33m" ;;
        jim.weller@mcg.com)   GIT_USER="work"; GIT_USER_ICON=$'\xEF\x91\xAE'; GIT_USER_COLOR="\033[38;5;196m" ;;
        "")                   GIT_USER="" ;;
        *)                    GIT_USER="$GIT_EMAIL"; GIT_USER_ICON=$'\xEF\x8A\xBB'; GIT_USER_COLOR="\033[38;5;29m" ;;
      esac
      ;;
  esac

  if git rev-parse --is-inside-work-tree &>/dev/null; then
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
[ -n "$CLOUD" ] && printf "${CLOUD_COLOR}${CLOUD}\033[0m "
printf "\033[38;5;117m${ICON_FOLDER} $DIR\033[0m"
[ -n "$GIT_USER" ] && printf " ${GIT_USER_COLOR}${GIT_USER_ICON} $GIT_USER\033[0m"
if [ -n "$BRANCH" ]; then
  printf " \033[33m${ICON_BRANCH} $BRANCH\033[0m"
  [ "$BEHIND" -gt 0 ] 2>/dev/null && printf " \033[96m⇣$BEHIND\033[0m"
  [ "$AHEAD" -gt 0 ] 2>/dev/null && printf " \033[96m⇡$AHEAD\033[0m"
  [ "$STASH" -gt 0 ] 2>/dev/null && printf " \033[95m*$STASH\033[0m"
  [ "$CONFLICTS" -gt 0 ] 2>/dev/null && printf " \033[91m~$CONFLICTS\033[0m"
  [ "$STAGED" -gt 0 ] 2>/dev/null && printf " \033[92m+$STAGED\033[0m"
  [ "$UNSTAGED" -gt 0 ] 2>/dev/null && printf " \033[93m!$UNSTAGED\033[0m"
  [ "$UNTRACKED" -gt 0 ] 2>/dev/null && printf " \033[97m?$UNTRACKED\033[0m"
fi
printf " ${CTX_COLOR}${CTX_ICON}\033[0m $MODEL"
printf "${EFFORT_COLOR}${EFFORT_TEXT}\033[0m"
printf " ${CTX_COLOR}${BAR_FILLED}\033[38;5;240m${BAR_EMPTY}\033[0m\033[38;5;250m${BAR_BUFFER}\033[0m ${CTX_COLOR}${CTX_USABLE}%% ${CTX_TOKENS_K}\033[0m"
if [ "$DAYS" -gt 0 ]; then
  DURATION="${DAYS}d${HOURS}h${MINS}m"
elif [ "$HOURS" -gt 0 ]; then
  DURATION="${HOURS}h${MINS}m"
else
  DURATION="${MINS}m"
fi
printf " \033[38;5;250m${ICON_TIMER} ${DURATION}\033[0m"
PROJECT_KEY=$(echo "$INPUT" | jq -r '.workspace.project_dir // "" | gsub("[/.]"; "-") | gsub("_"; "")')
CCUSAGE_CACHE="/tmp/ccusage-cache.json"
AZURE_CACHE="/tmp/azure-cost-cache.json"
COST_PROJECT=""
COST_MONTH=""
COST_MTD=""
PROJ_COST_RAW=""
PROJ_TOKENS=""
MTD_TOKENS=""
MONTH_TOKENS=""
MTD_RAW=""
MONTH_RAW=""
ACTUAL_RATIO=""
SESSION_TOKENS=""
if [ -f "$CCUSAGE_CACHE" ]; then
  DATE_30D=$(date -v-30d +%F 2>/dev/null || date -d '30 days ago' +%F)
  DATE_MONTH=$(date +%Y-%m-01)
  read -r PROJ_COST_RAW PROJ_TOKENS MTD_TOKENS MONTH_TOKENS <<<"$(jq -r \
    --arg p "$PROJECT_KEY" --arg m1 "$DATE_MONTH" --arg d30 "$DATE_30D" '
      [.projects[][]] as $all
      | (.projects[$p]? // []) as $proj
      | [([$proj[].totalCost] | add // 0),
         ([$proj[].totalTokens] | add // 0),
         ([$all[] | select(.date >= $m1) | .totalTokens] | add // 0),
         ([$all[] | select(.date >= $d30) | .totalTokens] | add // 0)]
      | @tsv' "$CCUSAGE_CACHE" 2>/dev/null)"
  [ "${PROJ_TOKENS:-0}" -gt 0 ] 2>/dev/null && COST_PROJECT=$(printf '%s' "$PROJ_COST_RAW" | awk '{printf "%.0f", $1}')
fi
if [ -f "$AZURE_CACHE" ]; then
  MTD_RAW=$(jq -r '.mtd // empty' "$AZURE_CACHE" 2>/dev/null)
  MONTH_RAW=$(jq -r '.rolling30d // empty' "$AZURE_CACHE" 2>/dev/null)
  ACTUAL_RATIO=$(jq -r '.actualRatio // empty' "$AZURE_CACHE" 2>/dev/null)
  [ -n "$MTD_RAW" ] && COST_MTD=$(printf '%s' "$MTD_RAW" | awk '{printf "%.0f", $1}')
  [ -n "$MONTH_RAW" ] && COST_MONTH=$(printf '%s' "$MONTH_RAW" | awk '{printf "%.0f", $1}')
fi
# Cumulative session tokens live only in the transcript. The statusline payload
# carries current context occupancy, which is a different number.
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  SESSION_TOKENS=$(jq -s '[.[] | .message.usage | select(. != null)
    | ((.input_tokens // 0) + (.output_tokens // 0)
       + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0))]
    | add // 0' "$TRANSCRIPT" 2>/dev/null)
fi
# Dollars per million tokens. Session and project costs are Anthropic list price,
# so they are repriced by what the platform actually billed. The Azure MTD and
# rolling-30d figures are already actual dollars and take no ratio.
fmte() {
  awk -v c="${1:-}" -v t="${2:-0}" -v r="${3:-}" 'BEGIN {
    if (c == "" || r == "" || t + 0 <= 0) exit
    v = sprintf("%.2f", c * r * 1000000 / t)
    sub(/^0\./, ".", v)
    print v
  }'
}
EFF_SESSION=$(fmte "$COST_RAW" "$SESSION_TOKENS" "$ACTUAL_RATIO")
EFF_PROJECT=$(fmte "$PROJ_COST_RAW" "$PROJ_TOKENS" "$ACTUAL_RATIO")
EFF_MTD=$(fmte "$MTD_RAW" "$MTD_TOKENS" 1)
EFF_MONTH=$(fmte "$MONTH_RAW" "$MONTH_TOKENS" 1)
fmtc() { LC_ALL=en_US.UTF-8 printf "%'d" "${1:-0}" 2>/dev/null || echo "${1:-0}"; }
COST=$(fmtc "$COST")
[ -n "$COST_PROJECT" ] && COST_PROJECT=$(fmtc "$COST_PROJECT")
[ -n "$COST_MTD" ] && COST_MTD=$(fmtc "$COST_MTD")
[ -n "$COST_MONTH" ] && COST_MONTH=$(fmtc "$COST_MONTH")
EFF_COLOR="\033[38;5;65m"
printf " \033[38;5;186m${ICON_CASH} \$${COST}\033[0m"
[ -n "$EFF_SESSION" ] && printf "${EFF_COLOR}${ICON_DIVISION}\$${EFF_SESSION}\033[0m"
[ -n "$COST_PROJECT" ] && printf " \033[38;5;186m${ICON_INVOICE} \$${COST_PROJECT}\033[0m"
[ -n "$EFF_PROJECT" ] && printf "${EFF_COLOR}${ICON_DIVISION}\$${EFF_PROJECT}\033[0m"
[ -n "$COST_MTD" ] && printf " \033[38;5;186m${ICON_CAL_TODAY} \$${COST_MTD}\033[0m"
[ -n "$EFF_MTD" ] && printf "${EFF_COLOR}${ICON_DIVISION}\$${EFF_MTD}\033[0m"
[ -n "$COST_MONTH" ] && printf " \033[38;5;186m${ICON_CAL_RANGE} \$${COST_MONTH}\033[0m"
[ -n "$EFF_MONTH" ] && printf "${EFF_COLOR}${ICON_DIVISION}\$${EFF_MONTH}\033[0m"

echo

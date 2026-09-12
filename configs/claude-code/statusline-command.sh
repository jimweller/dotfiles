#!/usr/bin/env bash

# prevent stale index.lock files. Blocks claude's commits https://github.com/anthropics/claude-code/issues/11005
GIT_OPTIONAL_LOCKS=0

# extglob carries the SGR-stripping pattern in emit()
shopt -s extglob

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

# Column ruler. Ink truncates each line against the box width, which is the terminal
# width less whatever chrome the surrounding layout takes, and that chrome is not
# readable from here. Touch the flag file, screenshot the statusline, read the last
# visible column off the ruler. Remove the flag file to restore the statusline.
if [ -f ~/tmp/sl-ruler ]; then
  RT=$(ps -o tty= -p $PPID 2>/dev/null | tr -d ' ')
  read -r RROWS RCOLS < <(stty size < "/dev/$RT" 2>/dev/null)
  # One row per candidate width. Each row is exactly N columns wide and ends in #.
  # A row whose # is visible fits; a row that ends in the ellipsis does not. The
  # largest N still showing # is the usable width.
  printf 'tty=%s cols=%s rows=%s\n' "$RT" "$RCOLS" "$RROWS"
  for n in $(seq $((RCOLS - 12)) "$RCOLS"); do
    printf -v SUB "%-4d" "$n"
    printf -v GRP "%$((n - 5))s" ""
    printf '%s%s#\n' "$SUB" "${GRP// /-}"
  done
  exit 0
fi

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

# The handle other sessions address with SendMessage. It is absent from the payload:
# session_name there is the /rename title or the AI title, and both are unset in most
# sessions. The registry under ~/.claude/sessions is keyed by the claude pid, and this
# script is spawned as a direct child of claude, so $PPID names the file outright.
HANDLE=""
[ -f "$HOME/.claude/sessions/$PPID.json" ] && HANDLE=$(jq -r '.name // empty' "$HOME/.claude/sessions/$PPID.json" 2>/dev/null)

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

# CTX_NUM and CTX_TEXT carry the same color as CTX_COLOR, split out because the
# effort letter paints it as a background and needs a foreground that survives it.
# Yellow and orange take black, the darker blue and red take white.
if [ "$CTX_USABLE" -gt 90 ]; then
  CTX_NUM=124
  CTX_TEXT=231
  CTX_ICON=$ICON_SKULL
elif [ "$CTX_USABLE" -ge 80 ]; then
  CTX_NUM=202
  CTX_TEXT=16
  CTX_ICON=$ICON_DEATH
elif [ "$CTX_USABLE" -ge 70 ]; then
  CTX_NUM=220
  CTX_TEXT=16
  CTX_ICON=$ICON_DUMB
else
  CTX_NUM=67
  CTX_TEXT=231
  CTX_ICON=$ICON_ROBOT
fi
CTX_COLOR="\033[38;5;${CTX_NUM}m"

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
# The effort letter takes the bar's first cell, painted as a background so the cell
# still reads as part of the bar. It costs that cell one block, keeping the bar 12
# wide and the wrap arithmetic unchanged. Which run the cell comes from depends on
# how full the bar is: filled at 9% and up, empty below that. The buffer branch is
# unreachable at BAR_WIDTH=12 and guards a narrower bar.
if [ "$FILLED" -gt 0 ]; then
  LEAD_BG=$CTX_NUM
  LEAD_FG=$CTX_TEXT
  FILLED=$((FILLED - 1))
elif [ "$EMPTY" -gt 0 ]; then
  LEAD_BG=240
  LEAD_FG=231
  EMPTY=$((EMPTY - 1))
else
  LEAD_BG=250
  LEAD_FG=16
  BUFFER_SHOW=$((BUFFER_SHOW - 1))
fi
BAR_LEAD="\033[48;5;${LEAD_BG};38;5;${LEAD_FG}m${EFFORT_TEXT}\033[0m"
BAR_FILLED=""
BAR_EMPTY=""
BAR_BUFFER=""
[ "$FILLED" -gt 0 ] && BAR_FILLED=$(printf "%${FILLED}s" | tr ' ' '█')
[ "$EMPTY" -gt 0 ] && BAR_EMPTY=$(printf "%${EMPTY}s" | tr ' ' '█')
[ "$BUFFER_SHOW" -gt 0 ] && BAR_BUFFER=$(printf "%${BUFFER_SHOW}s" | tr ' ' '░')

# Build statusline
#
# Segments are packed greedily. One that would overflow the terminal opens a new line
# rather than being chopped: Ink hands each line to a Text with wrap:"truncate", and
# the statusLine config carries no wrap option. The width comes from the tty of the
# claude process, because the payload has none and this script owns no terminal.
# Width counts characters with the SGR escapes stripped, which matches string-width's
# treatment of the private-use glyphs the icons come from as one column each.
# Ink measures against the box, which is 4 columns narrower than the tty. Measured
# with the ruler above at 145 columns: rows up to 141 kept their marker, 142 and wider
# came back ellipsized. Raising `padding` in the statusLine settings would widen this.
STATUS_CHROME=4
TERM_COLS=0
TERM_TTY=$(ps -o tty= -p $PPID 2>/dev/null | tr -d ' ')
if [ -n "$TERM_TTY" ] && [ "$TERM_TTY" != "??" ]; then
  read -r _ TERM_COLS < <(stty size < "/dev/$TERM_TTY" 2>/dev/null)
fi
[ -z "$TERM_COLS" ] && TERM_COLS=0
[ "$TERM_COLS" -gt "$STATUS_CHROME" ] && TERM_COLS=$((TERM_COLS - STATUS_CHROME))

OUT=""
LINE=""
LINE_W=0
emit() {
  local s=$1 plain w
  plain=${s//$'\033'\[*([0-9;])m/}
  w=${#plain}
  if [ "$TERM_COLS" -gt 0 ] && [ "$LINE_W" -gt 0 ] && [ $((LINE_W + w)) -gt "$TERM_COLS" ]; then
    OUT+="$LINE"$'\n'
    LINE=""
    LINE_W=0
    case $s in " "*) s=${s#" "}; w=$((w - 1)) ;; esac
  fi
  LINE+=$s
  LINE_W=$((LINE_W + w))
}

GRP=""
[ -n "$CLOUD" ] && printf -v GRP "${CLOUD_COLOR}${CLOUD}\033[0m "
printf -v SUB "\033[38;5;117m${ICON_FOLDER} $DIR\033[0m"
emit "${GRP}${SUB}"
if [ -n "$GIT_USER" ]; then
  printf -v GRP " ${GIT_USER_COLOR}${GIT_USER_ICON} $GIT_USER\033[0m"
  emit "$GRP"
fi
if [ -n "$BRANCH" ]; then
  printf -v GRP " \033[33m${ICON_BRANCH} $BRANCH\033[0m"
  [ "$BEHIND" -gt 0 ] 2>/dev/null && { printf -v SUB " \033[96m⇣$BEHIND\033[0m"; GRP+=$SUB; }
  [ "$AHEAD" -gt 0 ] 2>/dev/null && { printf -v SUB " \033[96m⇡$AHEAD\033[0m"; GRP+=$SUB; }
  [ "$STASH" -gt 0 ] 2>/dev/null && { printf -v SUB " \033[95m*$STASH\033[0m"; GRP+=$SUB; }
  [ "$CONFLICTS" -gt 0 ] 2>/dev/null && { printf -v SUB " \033[91m~$CONFLICTS\033[0m"; GRP+=$SUB; }
  [ "$STAGED" -gt 0 ] 2>/dev/null && { printf -v SUB " \033[92m+$STAGED\033[0m"; GRP+=$SUB; }
  [ "$UNSTAGED" -gt 0 ] 2>/dev/null && { printf -v SUB " \033[93m!$UNSTAGED\033[0m"; GRP+=$SUB; }
  [ "$UNTRACKED" -gt 0 ] 2>/dev/null && { printf -v SUB " \033[97m?$UNTRACKED\033[0m"; GRP+=$SUB; }
  emit "$GRP"
fi
if [ -n "$HANDLE" ]; then
  printf -v GRP " \033[38;5;141m@${HANDLE}\033[0m"
  emit "$GRP"
fi
printf -v GRP " ${CTX_COLOR}${CTX_ICON}\033[0m $MODEL"
emit "$GRP"
printf -v GRP " ${BAR_LEAD}${CTX_COLOR}${BAR_FILLED}\033[38;5;240m${BAR_EMPTY}\033[0m\033[38;5;250m${BAR_BUFFER}\033[0m ${CTX_COLOR}${CTX_USABLE}%% ${CTX_TOKENS_K}\033[0m"
emit "$GRP"
if [ "$DAYS" -gt 0 ]; then
  DURATION="${DAYS}d${HOURS}h${MINS}m"
elif [ "$HOURS" -gt 0 ]; then
  DURATION="${HOURS}h${MINS}m"
else
  DURATION="${MINS}m"
fi
printf -v GRP " \033[38;5;250m${ICON_TIMER} ${DURATION}\033[0m"
emit "$GRP"
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
# The four costs are one atom. They read as a row of related figures, so a break
# anywhere inside the row is worse than a break before it, and each amount keeps its
# dollars-per-million rate beside it.
MONEY=""
cost_seg() {
  local icon=$1 amount=$2 rate=$3
  [ -z "$amount" ] && return
  printf -v GRP " \033[38;5;186m${icon} \$${amount}\033[0m"
  [ -n "$rate" ] && { printf -v SUB "${EFF_COLOR}${ICON_DIVISION}\$${rate}\033[0m"; GRP+=$SUB; }
  MONEY+=$GRP
}
cost_seg "$ICON_CASH" "$COST" "$EFF_SESSION"
cost_seg "$ICON_INVOICE" "$COST_PROJECT" "$EFF_PROJECT"
cost_seg "$ICON_CAL_TODAY" "$COST_MTD" "$EFF_MTD"
cost_seg "$ICON_CAL_RANGE" "$COST_MONTH" "$EFF_MONTH"
[ -n "$MONEY" ] && emit "$MONEY"

OUT+="$LINE"
printf '%s\n' "$OUT"

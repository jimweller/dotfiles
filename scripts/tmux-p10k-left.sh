#!/usr/bin/env bash
# Renders tmux status-left matching p10k prompt style
# Args: $1 = pane_current_path

PANE_PATH="${1:-$HOME}"
BG=colour234
SUBSEP=$'\uE0B1'
FOLDER=$'\uF07B'
APPLE=$'\uF179'
PERSONAL_ICON=$'\uF2BB'
WORK_ICON=$'\uF46E'
GITHUB_ICON=$'\uF408'
AZURE_ICON=$'\uEBE8'

S="#[fg=colour242,bg=${BG}]${SUBSEP}#[none,bg=${BG}]"

# Inherit GIT_CONFIG_GLOBAL from tmux session environment
gcg=$(tmux show-environment GIT_CONFIG_GLOBAL 2>/dev/null | sed 's/^GIT_CONFIG_GLOBAL=//')
[[ -n "$gcg" && "$gcg" != "-GIT_CONFIG_GLOBAL" ]] && export GIT_CONFIG_GLOBAL="$gcg"

# --- os_icon ---
printf "#[fg=colour255,bg=${BG}] ${APPLE} "

# --- gituser ---
git_email=$(git -C "$PANE_PATH" config user.email 2>/dev/null)
case "$git_email" in
  jim.weller@gmail.com)
    printf "${S} #[fg=colour33,bg=${BG}]${PERSONAL_ICON} jw "
    ;;
  jim.weller@mcg.com)
    printf "${S} #[fg=colour196,bg=${BG}]${WORK_ICON} work "
    ;;
  "")
    ;;
  *)
    printf "${S} #[fg=colour33,bg=${BG}]${PERSONAL_ICON} ${git_email} "
    ;;
esac

# --- dir (leaf only) ---
if [[ "$PANE_PATH" == "$HOME" ]]; then
  leaf="~"
else
  leaf="${PANE_PATH##*/}"
fi
printf "${S} #[fg=colour39,bold,bg=${BG}]${FOLDER} ${leaf} "

# --- vcs (gitmux + brand icon) ---
GITMUX="${HOME}/.local/bin/gitmux"
GITMUX_CFG="${HOME}/.gitmux.yml"
if [[ -x "$GITMUX" ]] && git -C "$PANE_PATH" rev-parse --is-inside-work-tree &>/dev/null; then
  # Detect remote brand
  remote_url=$(git -C "$PANE_PATH" remote get-url origin 2>/dev/null)
  brand_icon=""
  case "$remote_url" in
    *github.com*)    brand_icon="${GITHUB_ICON}" ;;
    *dev.azure.com*|*visualstudio.com*) brand_icon="${AZURE_ICON}" ;;
  esac

  printf "${S} "
  [[ -n "$brand_icon" ]] && printf "#[fg=colour76,bg=${BG}]${brand_icon} "
  printf "$($GITMUX -cfg "$GITMUX_CFG" "$PANE_PATH")"
fi

printf " "

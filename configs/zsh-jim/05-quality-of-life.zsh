# quick otp generator function given a seed as a parameter
otp() { if [ -z $1 ]; then echo "Missing parameter, TOTP seed\nUsage: otp [seed] "; else oathtool --totp --b $1; fi }

# open my config files, opt for dotfiles now
cj() { vsc -n ~/.config/dotfiles }
dotfiles() { cd ~/.config/dotfiles && gl && ./install }

ef() { sync.sh & }

alias cbc='cb copy'
alias cbp='cb paste'

alias zs='cd ~/.config/dotfiles && ./install && antidote update && antidote load &&. ~/.zshrc'

unsetopt share_history

#unalias urlencode
urlencode() {
  urlenc enc
}

#unalias urldecode
urldecode() {
  urlenc dec
}

copyfile() {
  [[ -f "$1" ]] && cat $1 | cb copy
}
copypath() {
  pwd | cb copy
}

myip() {
  dig +short myip.opendns.com @resolver1.opendns.com
}

loadenv() { 
  set -a 
  if [[ -f "$1" ]]; then
    source "$1"
  else
    echo "❌"
  fi
  set +a; 
}

secret() { 
  loadenv "$HOME/.secrets/$1.env" 
}

if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Require non-official brew taps to be trusted via `brew trust`
# (allowlist seeded from configs/brew/trust.json -> ~/.homebrew/trust.json)
export HOMEBREW_REQUIRE_TAP_TRUST=1


# Set EDITOR and VISUAL variables - prefer 'code', then 'nano', fallback to 'vi'
if command -v code > /dev/null 2>&1; then
    export EDITOR="code -w"
    export VISUAL="code -w"
elif command -v nano > /dev/null 2>&1; then
    export EDITOR=nano
    export VISUAL=nano
else
    export EDITOR=vi
    export VISUAL=vi
fi

# Set PAGER variable - prefer 'bat' if available, otherwise use 'less'
if command -v bat > /dev/null 2>&1; then
    export PAGER=bat
else
    export PAGER=less
fi

# Set ripgrep config file location
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# JimContainer management alias (renamed from devcontainer to avoid VSCode conflict)
alias jimcontainer='jimcontainer.sh'
alias jimc='jimcontainer.sh'
alias secrets='secrets.sh'

bolt() {
  local name="${1:-jimweller-$(openssl rand -hex 2)}"
  quiver create "$name" --config "$HOME/.config/dotfiles/configs/quiver/bolt.yaml"
}


# enable zoxide smart change directory tool
# replace cd command
# This sad hack makes claude's bash tool not use zoxide
if [[ "$CLAUDECODE" != "1" ]]; then
    eval "$(zoxide init --cmd cd zsh)"
fi


# HISTORY_SUBSTRING_SEARCH_PREFIXED is a global variable that defines how the
# command history will be searched for your query. If set to a non-empty value,
# your query will be matched against the start of each history entry. For
# example, if this variable is empty, ls will match ls -l and echo ls; if it is
# non-empty, ls will only match ls -l.
HISTORY_SUBSTRING_SEARCH_PREFIXED=1

alias less=bat

# make pretty html files from basic markdown
markdown_to_html() {
  pandoc "$1" --css "$HOME/.config/dotfiles/assets/md.css" --embed-resources --standalone -o "${1%.*}.html"
}
alias md2html="markdown_to_html $1"

# Convert ISO 8601 date/time to local timezone (America/Los_Angeles)
# Usage: pdt 2026-01-22T15:55:06Z
#        echo "2026-01-22T15:55:06+00:00:00" | pdt
pdt() {
  local dt="${1:-$(cat)}"
  # Strip timezone suffixes (Z, +HH:MM:SS, +HH:MM)
  local clean_dt=$(echo "$dt" | sed -E 's/(Z|[+-][0-9]{2}:[0-9]{2}(:[0-9]{2})?)$//')
  
  # Convert to epoch (parse as UTC), then format in local timezone
  local epoch=$(date -juf "%Y-%m-%dT%H:%M:%S" "$clean_dt" "+%s" 2>/dev/null)
  
  if [[ $? -eq 0 ]]; then
    TZ="America/Los_Angeles" date -r "$epoch" "+%Y-%m-%d %H:%M:%S %Z"
  else
    echo "❌ Invalid date format. Expected ISO 8601 (e.g., 2026-01-22T15:55:06Z)"
  fi
}

mkdir_and_cd() {
  : "${1:?}"
  mkdir -p $1 && cd $1
}
alias mkd='mkdir_and_cd'

litellm-up() {
  if lsof -iTCP:4000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "litellm proxy already running on :4000"
    return 0
  fi
  nohup litellm --config ~/.config/litellm/config.yaml >/dev/null 2>&1 &
  local pid=$!
  local tries=0
  while ! lsof -iTCP:4000 -sTCP:LISTEN -t >/dev/null 2>&1; do
    sleep 0.5
    tries=$((tries + 1))
    if (( tries > 60 )); then
      echo "litellm proxy failed to start after 30s"
      return 1
    fi
  done
  echo "litellm proxy running (pid $pid) on :4000"
}

litellm-down() {
  local pids
  pids=$(lsof -iTCP:4000 -sTCP:LISTEN -t 2>/dev/null)
  if [[ -z "$pids" ]]; then
    echo "litellm proxy not running"
    return 0
  fi
  kill $pids 2>/dev/null
  echo "litellm proxy stopped"
}
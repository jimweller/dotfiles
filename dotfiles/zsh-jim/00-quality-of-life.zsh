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

# DevContainer management alias
alias devcontainer='devcontainer.sh'
alias devc='devcontainer.sh'
alias secrets='secrets.sh'


# enable zoxide smart change directory tool
# replace cd command
eval "$(zoxide init --cmd cd zsh)"


# HISTORY_SUBSTRING_SEARCH_PREFIXED is a global variable that defines how the
# command history will be searched for your query. If set to a non-empty value,
# your query will be matched against the start of each history entry. For
# example, if this variable is empty, ls will match ls -l and echo ls; if it is
# non-empty, ls will only match ls -l.
HISTORY_SUBSTRING_SEARCH_PREFIXED=1

alias less=bat

# Auto-load all secrets from ~/.secrets/*.env files
if [[ -d "$HOME/.secrets" ]]; then
  for secret_file in "$HOME/.secrets"/*.env; do
    if [[ -f "$secret_file" ]]; then
      source $secret_file
    fi
  done
fi
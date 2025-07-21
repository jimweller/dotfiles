# --- Begin clean PATH setup ---

# Always start fresh (important for VSCode, iTerm2, SSH)
unset PATH

# Set base system PATH
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"


# prepend go
if [ -d "$HOME/go/bin" ]; then
  export PATH="$HOME/go/bin:$PATH"
fi


# Prepend Homebrew
if [ -d "/opt/homebrew/bin" ]; then
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

  # use curl from brew instead of macos
  if command -v brew >/dev/null 2>&1 && command -v "$(brew --prefix)/opt/curl/bin/curl" >/dev/null 2>&1; then
    export PATH="$(brew --prefix)/opt/curl/bin:$PATH"
  fi

fi

# Add personal ~/bin if you have one
if [ -d "$HOME/bin" ]; then
  export PATH="$HOME/bin:$PATH"
fi

# add nix, mostly for devbox
if [ -d "/nix/var/nix/profiles/default/bin/" ]; then
  export PATH="/nix/var/nix/profiles/default/bin/:$PATH"
fi


# Add dotfiles scripts if available
if [ -d "$HOME/dotfiles/scripts" ]; then
  export PATH="$HOME/dotfiles/scripts:$PATH"
fi

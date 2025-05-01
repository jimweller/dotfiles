# --- Begin clean PATH setup ---

# Always start fresh (important for VSCode, iTerm2, SSH)
unset PATH

# Set base system PATH
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

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


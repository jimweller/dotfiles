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
if [ -d "$HOME/.config/dotfiles/scripts" ]; then
  export PATH="$HOME/.config/dotfiles/scripts:$PATH"
fi

# Add pipx install of az
if [ -d "$HOME/.local/bin" ]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

mkdir -p "$HOME/.go"
export GOPATH="$HOME/.go"
export PATH="$GOPATH/bin:$PATH"

# Initialize asdf (multiple installation methods)
if command -v brew >/dev/null 2>&1 && [ -f "$(brew --prefix asdf)/libexec/asdf.sh" ]; then
  # macOS with Homebrew
  . "$(brew --prefix asdf)/libexec/asdf.sh"
elif [ -f "/opt/asdf/asdf.sh" ]; then
  # Linux with system install (Dockerfile)
  . "/opt/asdf/asdf.sh"
elif [ -f "$HOME/.asdf/asdf.sh" ]; then
  # Linux with manual install
  . "$HOME/.asdf/asdf.sh"
fi

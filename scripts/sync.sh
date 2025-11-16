#!/bin/zsh
set -euo pipefail

# Load encryption password
if [[ -z "${DOTFILES_KEY:-}" ]]; then
  if [[ -f "$HOME/.secrets/dotfiles.env" ]]; then
    set -a
    source "$HOME/.secrets/dotfiles.env"
    set +a
  fi
fi

# Verify password is available
if [[ -z "${DOTFILES_KEY:-}" ]]; then
  echo "Error: DOTFILES_KEY not set. Please set it or add to ~/.secrets/dotfiles.env"
  exit 1
fi

# Sparse image variables
PASSWORD="${DOTFILES_KEY}"
DMG="$HOME/jim.weller@gmail.com - Google Drive/My Drive/PortfolioJim/current/backup.dmg.sparseimage"
MOUNT="/Volumes/Backup"
SIZE="16g"
TARGET_DIR="$MOUNT"

# Create parent directory for DMG if needed
echo "Ensuring backup directory exists..."
mkdir -p "$(dirname "$DMG")"

# Create encrypted sparse image if it doesn't exist
if [[ ! -f "$DMG" ]]; then
  echo "Creating encrypted sparse image..."
  echo "$PASSWORD" | hdiutil create -encryption -type SPARSE -stdinpass -size "$SIZE" -volname Backup -fs APFS "$DMG"
fi

# Mount encrypted sparse image
echo "Mounting encrypted backup volume..."
echo "$PASSWORD" | hdiutil attach "$DMG" -stdinpass -mountpoint "$MOUNT"

# Generate brew + extensions
echo "Backing up Homebrew and VS Code extensions..."
brew leaves > "$TARGET_DIR/brew-formulas.txt"
brew list --cask > "$TARGET_DIR/brew-casks.txt"
brew tap > "$TARGET_DIR/brew-taps.txt"
code --list-extensions > "$TARGET_DIR/vscode-extensions.txt"

# Rsync everything to target directory
echo "Syncing files to encrypted volume..."
rsync -avL --delete \
  --exclude='.Trash' \
  --exclude='.trash' \
  --exclude='.git' \
  --exclude='.DS_Store' \
  --exclude='__pycache__' \
  --exclude='*.pyc' \
  --exclude='.pytest_cache' \
  --exclude='.mypy_cache' \
  --exclude='.ruff_cache' \
  --exclude='.tox' \
  --exclude='.venv' \
  --exclude='venv' \
  --exclude='node_modules' \
  --exclude='.next' \
  --exclude='.nuxt' \
  --exclude='dist' \
  --exclude='build' \
  --exclude='.cache' \
  --exclude='target' \
  --exclude='vendor' \
  --exclude='.terraform' \
  --exclude='.terraform.lock.hcl' \
  --exclude='.terragrunt-cache' \
  --exclude='.kube/cache' \
  --exclude='.kube/http-cache' \
  ~/work \
  ~/personal \
  ~/tmp \
  ~/Library/Preferences/com.microsoft.VSCode.plist \
  ~/Library/Saved\ Application\ State/com.microsoft.VSCode.savedState \
  ~/Library/Application\ Support/Code/User/settings.json \
  ~/Library/Application\ Support/Code/User/keybindings.json \
  ~/Library/Application\ Support/Google/Chrome/Profile\ 1/Bookmarks \
  ~/Library/CloudStorage/OneDrive \
  "$TARGET_DIR/"

echo "Sync complete."

# Unmount encrypted volume
echo "Unmounting backup volume..."
hdiutil detach "$MOUNT"

echo "Encrypted backup complete: $DMG"

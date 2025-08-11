#!/bin/zsh
set -euo pipefail

# Variables
TARGET_DIR="$HOME/Google Drive/My Drive/PortfolioJim/MCG/EF"

# Create target directory if it doesn't exist
echo "Ensuring backup directory exists at $TARGET_DIR..."
mkdir -p "$TARGET_DIR"

# Generate brew + extensions
echo "Backing up Homebrew and VS Code extensions..."
brew list --formula > "$TARGET_DIR/brew-formulas.txt"
brew list --cask > "$TARGET_DIR/brew-casks.txt"
brew tap > "$TARGET_DIR/brew-taps.txt"
code --list-extensions > "$TARGET_DIR/vscode-extensions.txt"

# Rsync everything to target directory
echo "Syncing files to Google Drive..."
rsync -avL --delete \
  --exclude='.Trash' \
  --exclude='.trash' \
  --exclude='.git' \
  --exclude='.kube/cache' \
  --exclude='.kube/http-cache' \
  --exclude='.terraform' \
  --exclude='.venv' \
  ~/Projects/work \
  ~/Projects/personal \
  ~/Library/Preferences/com.microsoft.VSCode.plist \
  ~/Library/Saved\ Application\ State/com.microsoft.VSCode.savedState \
  ~/Library/Application\ Support/Code/User/settings.json \
  ~/Library/Application\ Support/Code/User/keybindings.json \
  ~/Library/Application\ Support/Google/Chrome/Profile\ 1/Bookmarks \
  ~/Library/CloudStorage/OneDrive \
  "$TARGET_DIR/"

echo "Sync complete."

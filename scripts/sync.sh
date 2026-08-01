#!/bin/zsh
set -euo pipefail

TARGET_DIR="${DOTFILES_BACKUP_DIR:-$HOME/bak/PortfolioJim/current}"

echo "Ensuring backup directory exists..."
mkdir -p "$TARGET_DIR"

# Generate brew + extensions
echo "Backing up Homebrew and VS Code extensions..."
brew leaves > "$TARGET_DIR/brew-formulas.txt"
brew list --cask > "$TARGET_DIR/brew-casks.txt"
brew tap > "$TARGET_DIR/brew-taps.txt"
code --list-extensions > "$TARGET_DIR/vscode-extensions.txt"

# Backup Confluence pages
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
echo ""
echo "Backing up Confluence pages..."
CONFLUENCE_BACKUP="$SCRIPT_DIR/confluence-backup.sh"
if [[ -f "$CONFLUENCE_BACKUP" ]]; then
    "$CONFLUENCE_BACKUP" "$TARGET_DIR/Confluence"
    if [[ $? -eq 0 ]]; then
        echo "✓ Confluence backup complete"
    else
        echo "⚠ Confluence backup failed (continuing with sync)"
    fi
else
    echo "⚠ confluence-backup.sh not found at $CONFLUENCE_BACKUP, skipping Confluence backup"
fi

echo ""
echo "Syncing files to $TARGET_DIR..."
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
  --exclude='assets/qdrant' \
  --exclude='assets/postgres' \
  --exclude='kics/test/fixtures' \
  --filter=':- .gitignore' \
  ~/work \
  ~/personal \
  ~/assets \
  ~/Library/Preferences/com.microsoft.VSCode.plist \
  ~/Library/Application\ Support/Code/User/settings.json \
  ~/Library/Application\ Support/Code/User/keybindings.json \
  ~/Library/Application\ Support/Google/Chrome/Default/Bookmarks \
  ~/Library/CloudStorage/OneDrive-Hearst \
  "$TARGET_DIR/"

echo "Backup complete: $TARGET_DIR"

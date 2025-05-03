#!/bin/zsh
set -euo pipefail

set -a
source "$HOME/.secrets/exfl.env"
set +a

# Variables
PASSWORD="${SYNC_ENCRYPTION_PASSWORD:?Set SYNC_ENCRYPTION_PASSWORD}"
DMG="$HOME/Projects/WorkPortfolio/WorkPortfolio.dmg.sparseimage"
MOUNT="/Volumes/WorkPortfolio"
SIZE="16g"

# Create encrypted DMG if it doesn't exist
if [ ! -f "$DMG" ]; then
  echo "$PASSWORD" | hdiutil create -encryption -type SPARSE -stdinpass -size "$SIZE" -volname WorkPortfolio -fs APFS "$DMG"
fi

# Mount encrypted DMG
echo "$PASSWORD" | hdiutil attach "$DMG" -stdinpass -mountpoint "$MOUNT"

# Generate brew + extensions
brew list --formula > "$MOUNT/brew-formulas.txt"
brew list --cask > "$MOUNT/brew-casks.txt"
brew tap > "$MOUNT/brew-taps.txt"
code --list-extensions > "$MOUNT/vscode-extensions.txt"

# Rsync everything to mounted volume
rsync -avL --delete \
  ~/Projects/work/ \
  ~/Projects/personal/ \
  ~/Library/Preferences/com.microsoft.VSCode.plist \
  ~/Library/Preferences/com.visualstudio.code.oss.plist \
  ~/Library/Saved\ Application\ State/com.microsoft.VSCode.savedState \
  ~/Library/Application\ Support/Code/User/settings.json \
  ~/Library/Application\ Support/Code/User/keybindings.json \
  ~/Library/Application\ Support/Code/User/snippets/ \
  ~/Library/Application\ Support/Google/Chrome/Profile\ 1/Bookmarks \
  ~/.git* \
  ~/.config/gh \
  ~/.gnupg/ \
  ~/.ssh/ \
  ~/.kube \
  ~/Library/CloudStorage/OneDrive-HylandSoftware/Documents/ \
  ~/Library/CloudStorage/OneDrive-HylandSoftware/Drawings/ \
  ~/Library/CloudStorage/OneDrive-HylandSoftware/Exfl/ \
  ~/Library/CloudStorage/OneDrive-HylandSoftware/Images/ \
  ~/Library/CloudStorage/OneDrive-HylandSoftware/notes.txt \
  ~/Library/CloudStorage/OneDrive-HylandSoftware/passwi.kdbx \
  "$MOUNT/"

# Unmount
hdiutil detach "$MOUNT"

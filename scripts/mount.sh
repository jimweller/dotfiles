#!/bin/zsh
set -euo pipefail

# Check if DMG file path is provided as argument
DMG_FILE="${1:?Usage: $0 <path-to-dmg-file>}"

# Check if the DMG file actually exists
if [ ! -f "$DMG_FILE" ]; then
  echo "Error: DMG file does not exist: $DMG_FILE" >&2
  exit 1
fi

# Check if environment file exists before sourcing
ENV_FILE="$HOME/.secrets/dotfiles.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: Environment file does not exist: $ENV_FILE" >&2
  exit 1
fi

# Source environment file for password
set -a
source "$ENV_FILE"
set +a

# Get password from environment with fail-fast
PASSWORD="${DOTFILES_KEY:?Set DOTFILES_KEY}"

# Check if hdiutil command is available
if ! command -v hdiutil >/dev/null 2>&1; then
  echo "Error: hdiutil command not found. This script requires macOS." >&2
  exit 1
fi

# Extract filename without path and extension for mount point
BASENAME=$(basename "$DMG_FILE" .dmg.sparseimage)
BASENAME=$(basename "$BASENAME" .dmg)
MOUNT="/Volumes/$BASENAME"

echo "Mounting: $DMG_FILE"
echo "Mount point: $MOUNT"

# Check if mount point already exists and is in use
if [ -d "$MOUNT" ] && mountpoint -q "$MOUNT" 2>/dev/null; then
  echo "Error: Mount point $MOUNT is already in use" >&2
  exit 1
fi

# Mount encrypted DMG using secure password handling
printf '%s\n' "$PASSWORD" | hdiutil attach "$DMG_FILE" -stdinpass -mountpoint "$MOUNT"

if [ $? -eq 0 ]; then
  echo "Successfully mounted $DMG_FILE at $MOUNT"
else
  echo "Failed to mount $DMG_FILE" >&2
  exit 1
fi
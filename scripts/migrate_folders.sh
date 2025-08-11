#!/bin/zsh
set -euo pipefail

# --- Configuration ---
ONEDRIVE_PATH="$HOME/Library/CloudStorage/OneDrive-Hearst"
FOLDERS_TO_MIGRATE=("Documents" "Movies" "Music" "Pictures")

# --- Migration Logic ---
for FOLDER in "${FOLDERS_TO_MIGRATE[@]}"; do
  SOURCE_PATH="$HOME/$FOLDER"
  BACKUP_PATH="$HOME/${FOLDER}.bak"
  DEST_PATH="$ONEDRIVE_PATH/$FOLDER"

  echo "Migrating $FOLDER..."

  # 1. Rename the original folder
  if [ -d "$SOURCE_PATH" ] && [ ! -L "$SOURCE_PATH" ]; then
    echo "  - Backing up original $FOLDER to ${FOLDER}.bak"
    mv "$SOURCE_PATH" "$BACKUP_PATH"
  else
    echo "  - Skipping backup, $SOURCE_PATH is already a symlink or does not exist."
    continue
  fi

  # 2. Create the symbolic link
  echo "  - Creating symbolic link for $FOLDER"
  ln -s "$DEST_PATH" "$SOURCE_PATH"

  # 3. Move the content from the backup to the new location
  echo "  - Moving content to OneDrive..."
  # Use rsync to move all files, including hidden ones.
  rsync -av --remove-source-files "$BACKUP_PATH/" "$DEST_PATH/"

  # 4. Remove the empty backup directory
  echo "  - Cleaning up backup directory..."
  rmdir "$BACKUP_PATH"

  echo "$FOLDER migration complete."
  echo "--------------------------------"
done

echo "All folder migrations are complete!"
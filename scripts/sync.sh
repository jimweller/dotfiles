#!/bin/zsh
set -euo pipefail

TARGET_DIR="${DOTFILES_BACKUP_DIR:-$HOME/bak/PortfolioJim/current}"

# Refuse to run unless ~/bak resolves into a live Google Drive mount. A dangling
# symlink here is otherwise materialized as a plain local directory by mkdir -p,
# sending every backup to the internal disk with no sync and no error.
#
# Resolve with readlink, not `cd && pwd -P`. Inside a FileProvider domain getcwd
# fails with EPERM unless this process holds a TCC grant, and zsh then falls
# back to the logical $PWD, which makes a correct symlink look broken.
if [[ -z "${DOTFILES_BACKUP_DIR:-}" ]]; then
    BACKUP_ROOT="$HOME/bak"

    if [[ ! -L "$BACKUP_ROOT" ]]; then
        echo "ERROR: $BACKUP_ROOT is not a symlink; expected a link into ~/Library/CloudStorage"
        exit 1
    fi

    RESOLVED_ROOT="$(readlink "$BACKUP_ROOT")"
    if [[ "$RESOLVED_ROOT" != "$HOME/Library/CloudStorage/"* ]]; then
        echo "ERROR: $BACKUP_ROOT resolves to $RESOLVED_ROOT, outside ~/Library/CloudStorage"
        echo "Backups would land on local disk and never sync. Refusing to run."
        exit 1
    fi

    # The domain must be readable. Without a TCC grant for the running binary
    # every read inside it fails with EPERM, and at login it can be unmounted.
    if ! ls "$RESOLVED_ROOT" >/dev/null 2>&1; then
        echo "ERROR: $RESOLVED_ROOT is not readable"
        echo "Either Google Drive is not mounted yet, or $0 lacks a TCC grant for this domain."
        exit 1
    fi

    if [[ ! -d "$RESOLVED_ROOT/PortfolioJim" ]]; then
        echo "ERROR: $RESOLVED_ROOT/PortfolioJim is missing; the mount looks incomplete"
        exit 1
    fi
fi

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
CONFLUENCE_STATUS="ok"
if [[ -f "$CONFLUENCE_BACKUP" ]]; then
    confluence_rc=0
    "$CONFLUENCE_BACKUP" "$TARGET_DIR/Confluence" || confluence_rc=$?
    if [[ $confluence_rc -eq 0 ]]; then
        echo "Confluence backup complete"
    else
        echo "ERROR: Confluence backup failed (exit $confluence_rc); continuing with file sync"
        CONFLUENCE_STATUS="failed (exit $confluence_rc)"
    fi
else
    echo "ERROR: confluence-backup.sh not found at $CONFLUENCE_BACKUP"
    CONFLUENCE_STATUS="missing"
fi

echo ""

# OneDrive Files On-Demand leaves placeholder files carrying the `dataless`
# flag. The bytes are not on disk, so rsync reading one forces a download.
# Under launchd that download fails with EDEADLK ("Resource deadlock avoided"),
# rsync discards the partial file as "failed verification", and the whole run
# exits 23. Measured before this exclusion: 95 placeholders totalling 6.6G were
# re-read on every nightly run, none of them ever transferring.
#
# Skip them by path. They stay in OneDrive, which is itself cloud storage, so
# nothing is lost that was ever held locally.
ONEDRIVE_ROOT="$HOME/Library/CloudStorage/OneDrive-Hearst"
DATALESS_EXCLUDES="$(mktemp)"
DATALESS_ERRS="$(mktemp)"
trap 'rm -f "$DATALESS_EXCLUDES" "$DATALESS_ERRS"' EXIT

# Patterns are anchored to the rsync transfer root, which starts at
# OneDrive-Hearst. Wildcard characters in a filename would otherwise be read as
# glob metacharacters, so escape backslashes first, then [ ] * ?.
find "$ONEDRIVE_ROOT" -flags +dataless -type f -print 2>"$DATALESS_ERRS" \
  | sed -e "s|^$HOME/Library/CloudStorage/|/|" \
        -e 's/[\\]/\\\\/g' \
        -e 's/[][*?]/\\&/g' \
  > "$DATALESS_EXCLUDES"

dataless_count=$(wc -l < "$DATALESS_EXCLUDES" | tr -d ' ')
echo "Skipping $dataless_count dataless OneDrive placeholder(s)"
if [[ -s "$DATALESS_ERRS" ]]; then
  echo "WARNING: scanning $ONEDRIVE_ROOT reported errors; the skip list may be incomplete"
  head -3 "$DATALESS_ERRS"
fi

echo "Syncing files to $TARGET_DIR..."
SYNC_STATUS="ok"
rsync_rc=0
rsync -avL --delete \
  --exclude-from="$DATALESS_EXCLUDES" \
  --exclude='OneDrive-Hearst/Recordings' \
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
  --exclude='OneDrive-Hearst/emojis' \
  --filter=':- .gitignore' \
  ~/work \
  ~/personal \
  ~/assets \
  ~/Library/Preferences/com.microsoft.VSCode.plist \
  ~/Library/Application\ Support/Code/User/settings.json \
  ~/Library/Application\ Support/Code/User/keybindings.json \
  ~/Library/Application\ Support/Google/Chrome/Default/Bookmarks \
  ~/Library/CloudStorage/OneDrive-Hearst \
  "$TARGET_DIR/" || rsync_rc=$?

if [[ $rsync_rc -eq 0 ]]; then
  echo "File sync complete"
elif [[ $rsync_rc -eq 23 || $rsync_rc -eq 24 ]]; then
  echo "ERROR: rsync partial transfer (exit $rsync_rc); some files were not copied, see backup-err.txt"
  SYNC_STATUS="partial (exit $rsync_rc)"
else
  echo "ERROR: rsync failed (exit $rsync_rc)"
  exit $rsync_rc
fi

if [[ "$CONFLUENCE_STATUS" != "ok" || "$SYNC_STATUS" != "ok" ]]; then
  echo "Backup finished with errors: confluence=$CONFLUENCE_STATUS sync=$SYNC_STATUS"
  exit 1
fi

echo "Backup complete: $TARGET_DIR"

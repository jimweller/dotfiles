#!/bin/zsh
set -euo pipefail

# Fix hardcoded /Users/jimweller paths in Claude Code config files.
# Safe to run on macOS (no-op) and in devcontainers (rewrites to $HOME).

ORIGINAL="/Users/jimweller"

files=(
  ~/.claude/plugins/installed_plugins.json
  ~/.claude/plugins/known_marketplaces.json
)

for f in "${files[@]}"; do
  if [[ -f "$f" ]]; then
    sed -i'' "s|$ORIGINAL|$HOME|g" "$f"
    echo "Fixed: $f"
  else
    echo "Skipped (not found): $f"
  fi
done

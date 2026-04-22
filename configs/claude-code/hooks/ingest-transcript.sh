#!/bin/bash
set -euo pipefail

INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path')
CWD=$(echo "$INPUT" | jq -r '.cwd')
PROJECT=$(basename "$CWD")

[ -f "$TRANSCRIPT_PATH" ] || exit 1

TR="$HOME/.config/dotfiles/configs/claude-code/tools/total-recall"
DB="$HOME/.claude/session_memory.db"

"$TR/.venv/bin/python" "$TR/ingest.py" "$TRANSCRIPT_PATH" --db "$DB" --project "$PROJECT" --no-embed

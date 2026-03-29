#!/bin/bash
set -euo pipefail

TR="/Users/jimweller/.config/dotfiles/dotfiles/claude-code/tools/total-recall"
PY="$TR/.venv/bin/python"
DB="/Users/jimweller/.claude/session_memory.db"

[ -f "$DB" ] || exit 0

"$PY" "$TR/backfill_embeddings.py" --db "$DB"
"$PY" "$TR/vecdb.py" --db "$DB"
"$PY" "$TR/semantic_linker.py" --db "$DB"

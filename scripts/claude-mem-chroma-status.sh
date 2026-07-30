#!/usr/bin/env bash
#
# Reports true Chroma coverage for claude-mem by comparing rows in the SQLite
# database against documents actually present in the Chroma store.
#
# Watermarks in chroma-sync-state.json report intent, not contents. A backfill
# can log success while skipping rows, so this script ignores watermarks and
# counts documents directly.
#
# Usage:
#   claude-mem-chroma-status.sh              summary
#   claude-mem-chroma-status.sh -p           summary plus per-project gaps
#   claude-mem-chroma-status.sh -i           emit missing ids as JSON

set -euo pipefail

DATA_DIR="${CLAUDE_MEM_DATA_DIR:-$HOME/.claude-mem}"
MEM_DB="$DATA_DIR/claude-mem.db"
CHROMA_DB="$DATA_DIR/chroma/chroma.sqlite3"
PORT="${CLAUDE_MEM_WORKER_PORT:-37777}"

SHOW_PROJECTS=0
EMIT_IDS=0
while getopts "pih" opt; do
  case "$opt" in
    p) SHOW_PROJECTS=1 ;;
    i) EMIT_IDS=1 ;;
    h) sed -n '3,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) exit 2 ;;
  esac
done

for f in "$MEM_DB" "$CHROMA_DB"; do
  if [ ! -f "$f" ]; then
    echo "missing: $f" >&2
    exit 1
  fi
done

# Both databases are opened read-only. chroma.sqlite3 is held open by the
# running chroma-mcp process, so a writable handle would contend with it.
query() {
  sqlite3 "file:$MEM_DB?mode=ro" <<SQL
ATTACH DATABASE 'file:$CHROMA_DB?mode=ro' AS c;
$1
SQL
}

# Chroma stores one row per (document, metadata key). A document's source row
# is c.embedding_metadata.int_value where key='sqlite_id', partitioned by the
# doc_type key on the same document id. sqlite_id values collide across types,
# so the doc_type join is required for a correct comparison.
present_ids() {
  cat <<SQL
SELECT DISTINCT m.int_value
FROM c.embedding_metadata m
JOIN c.embedding_metadata t ON t.id = m.id AND t.key = 'doc_type'
WHERE m.key = 'sqlite_id' AND m.int_value IS NOT NULL AND t.string_value = '$1'
SQL
}

# Emits {project: {observations: [...], summaries: [...], prompts: [...]}}.
# user_prompts carries no project column, so it resolves through sdk_sessions
# exactly as upstream's backfillPrompts does (ChromaSync.ts:922-924).
if [ "$EMIT_IDS" -eq 1 ]; then
  query "
.mode list
.separator |
SELECT project, kind, group_concat(id) FROM (
  SELECT project, 'observations' AS kind, id
  FROM observations
  WHERE project IS NOT NULL AND project != ''
    AND id NOT IN ($(present_ids observation))
  UNION ALL
  SELECT project, 'summaries', id
  FROM session_summaries
  WHERE project IS NOT NULL AND project != ''
    AND id NOT IN ($(present_ids session_summary))
  UNION ALL
  SELECT s.project, 'prompts', up.id
  FROM user_prompts up
  JOIN sdk_sessions s ON up.session_db_id = s.id
  WHERE s.project IS NOT NULL AND s.project != ''
    AND up.id NOT IN ($(present_ids user_prompt))
)
GROUP BY project, kind
ORDER BY project, kind;"
  exit 0
fi

echo "claude-mem chroma coverage"
echo

health=$(curl -sf --max-time 5 "http://localhost:$PORT/api/chroma/status?deep=true" 2>/dev/null || echo "")
if [ -n "$health" ]; then
  echo "  worker:  $(printf '%s' "$health" | sed -n 's/.*"status":"\([^"]*\)".*/\1/p')"
  echo "  probe:   $(printf '%s' "$health" | sed -n 's/.*"details":"\([^"]*\)".*/\1/p')"
else
  echo "  worker:  unreachable on port $PORT"
fi
echo "  store:   $(du -sh "$DATA_DIR/chroma" 2>/dev/null | cut -f1)"
echo

# A row is INDEXABLE only if it yields at least one document. formatObservationDocs
# emits nothing when narrative, text, and facts are all empty, and the summary and
# prompt formatters behave the same way. Counting those rows as missing reports a
# gap that can never close, so they are excluded from MISSING and shown separately.
OBS_INDEXABLE="COALESCE(NULLIF(narrative,''), NULLIF(text,''), NULLIF(NULLIF(facts,'[]'),'')) IS NOT NULL"
SUM_INDEXABLE="COALESCE(NULLIF(request,''), NULLIF(investigated,''), NULLIF(learned,''), NULLIF(completed,''), NULLIF(next_steps,''), NULLIF(notes,'')) IS NOT NULL"
PROMPT_INDEXABLE="NULLIF(prompt_text,'') IS NOT NULL"

printf '  %-18s %8s %10s %9s %9s %7s\n' TABLE ROWS INDEXABLE INDEXED MISSING GAP
query "
.mode list
.separator |
SELECT 'observations', COUNT(*), SUM($OBS_INDEXABLE),
       SUM(id IN ($(present_ids observation))),
       SUM($OBS_INDEXABLE AND id NOT IN ($(present_ids observation)))
FROM observations
UNION ALL
SELECT 'session_summaries', COUNT(*), SUM($SUM_INDEXABLE),
       SUM(id IN ($(present_ids session_summary))),
       SUM($SUM_INDEXABLE AND id NOT IN ($(present_ids session_summary)))
FROM session_summaries
UNION ALL
SELECT 'user_prompts', COUNT(*), SUM($PROMPT_INDEXABLE),
       SUM(id IN ($(present_ids user_prompt))),
       SUM($PROMPT_INDEXABLE AND id NOT IN ($(present_ids user_prompt)))
FROM user_prompts;" |
while IFS='|' read -r tbl rows indexable indexed missing; do
  pct=$(awk -v m="$missing" -v r="$indexable" 'BEGIN{ if (r+0 > 0) printf "%.1f%%", 100*m/r; else printf "n/a" }')
  printf '  %-18s %8s %10s %9s %9s %7s\n' "$tbl" "$rows" "$indexable" "$indexed" "$missing" "$pct"
done

if [ "$SHOW_PROJECTS" -eq 1 ]; then
  echo
  echo "  projects with missing observations (worst 20)"
  printf '  %-42s %8s %8s %7s\n' PROJECT MISSING TOTAL GAP
  query "
.mode list
.separator |
SELECT project,
       SUM($OBS_INDEXABLE AND id NOT IN ($(present_ids observation))) AS missing,
       SUM($OBS_INDEXABLE) AS total
FROM observations
WHERE project IS NOT NULL AND project != ''
GROUP BY project
HAVING missing > 0
ORDER BY missing DESC
LIMIT 20;" |
  while IFS='|' read -r proj missing total; do
    pct=$(awk -v m="$missing" -v t="$total" 'BEGIN{ if (t+0 > 0) printf "%.0f%%", 100*m/t; else printf "n/a" }')
    printf '  %-42s %8s %8s %7s\n' "$proj" "$missing" "$total" "$pct"
  done
fi

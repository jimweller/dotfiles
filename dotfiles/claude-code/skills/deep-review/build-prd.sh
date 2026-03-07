#!/usr/bin/env bash
set -euo pipefail

PHASE1_DIR="$1"
WORKDIR="$2"
PROJECT_ROOT="$3"

WORKLIST_FILE="$PHASE1_DIR/worklist.json"
OUTPUT_FILE="$WORKDIR/PRD.md"

cat > "$OUTPUT_FILE" << 'HEADER'
# Deep Code Review Tasks

Review each entity/cluster through the specified focus area lens. Follow the
investigation protocol in CLAUDE.md. Append findings to the specified review document.

HEADER

# Get unique focus areas, ordered by max priority_score descending
FOCUS_AREAS=$(jq -r '[group_by(.focus)[] | {focus: .[0].focus, max_score: (map(.priority_score) | max)}] | sort_by(-.max_score) | .[].focus' "$WORKLIST_FILE")

for focus in $FOCUS_AREAS; do
  echo "## $focus" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"

  # Generate one checkbox per cluster, sorted by priority_score desc
  jq -r --arg focus "$focus" --arg root "$PROJECT_ROOT" '
    [.[] | select(.focus == $focus)] | sort_by(-.priority_score) | .[] |
    if (.entities | length) == 1 then
      .entities[0] as $e |
      "- [ ] Review: \($e.entity) (\($e.file):\($e.line), fan-in:\($e.fan_in)). Focus: \(.focus). Write to \($root)/.llmdocs/_deep-review-\(.focus).md"
    else
      "- [ ] Review cluster: " + (
        [.entities[] | "\(.entity) (\(.file):\(.line), fan-in:\(.fan_in))"]
        | join(" -> ")
      ) + ". Focus: \(.focus). Write to \($root)/.llmdocs/_deep-review-\(.focus).md"
    end
  ' "$WORKLIST_FILE" >> "$OUTPUT_FILE"

  echo "" >> "$OUTPUT_FILE"
done

echo "PRD.md written: $OUTPUT_FILE"

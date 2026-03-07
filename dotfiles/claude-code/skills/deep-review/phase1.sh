#!/usr/bin/env bash
set -euo pipefail

TARGET_ABS="$1"
TARGET_NAME="$2"
PROJECT_ROOT="$3"
SKILL_DIR="$4"
JOERN_FRONTEND="$5"
if [ -z "$JOERN_FRONTEND" ]; then
  echo "ERROR: JOERN_FRONTEND (arg 5) is required" >&2
  exit 1
fi

PHASE1_DIR="$PROJECT_ROOT/.codereview/phase1"
WORKDIR="$PROJECT_ROOT/.codereview/phase2b-workdir"

mkdir -p "$PHASE1_DIR"
mkdir -p "$WORKDIR"

echo "=== Phase 1: Context Generation ==="
echo "Target: $TARGET_ABS"
echo "Target name: $TARGET_NAME"
echo ""

# --- Step 1: Joern parse ---
echo "--- 1a. joern-parse ($JOERN_FRONTEND) ---"
joern-parse --language "$JOERN_FRONTEND" -o "$PHASE1_DIR/cpg.bin" "$TARGET_ABS"
echo "CPG created: $PHASE1_DIR/cpg.bin"
echo ""

# --- Step 2: Joern extract ---
echo "--- 1b. joern extract-cpg.sc ---"
joern --script "$SKILL_DIR/extract-cpg.sc" \
  --param "cpgFile=$PHASE1_DIR/cpg.bin" \
  --param "outDir=$PHASE1_DIR"
echo ""

# Verify extraction produced output
if [ ! -f "$PHASE1_DIR/entities.jsonl" ]; then
  echo "ERROR: entities.jsonl not created" >&2
  exit 1
fi

echo "Entity summary:"
cat "$PHASE1_DIR/entity-summary.txt"
echo ""

# --- Step 3: Grep passes ---
echo "--- 1c. Grep passes ---"

# Map Joern frontend to source file extensions
case "$JOERN_FRONTEND" in
  csharpsrc) GREP_INCLUDES="--include=*.cs --include=*.csx --include=*.cshtml --include=*.razor" ;;
  javasrc)   GREP_INCLUDES="--include=*.java --include=*.jsp --include=*.jspx" ;;
  pythonsrc) GREP_INCLUDES="--include=*.py --include=*.pyi" ;;
  jssrc)     GREP_INCLUDES="--include=*.js --include=*.jsx --include=*.ts --include=*.tsx --include=*.mjs --include=*.cjs" ;;
  gosrc)     GREP_INCLUDES="--include=*.go" ;;
  newc)      GREP_INCLUDES="--include=*.c --include=*.h" ;;
  cppsrc)    GREP_INCLUDES="--include=*.cpp --include=*.cc --include=*.cxx --include=*.hpp --include=*.h --include=*.hxx" ;;
  *)         GREP_INCLUDES="" ;;
esac

# Also include config/infra files relevant to all languages
GREP_INCLUDES="$GREP_INCLUDES --include=*.xml --include=*.json --include=*.yaml --include=*.yml --include=*.toml --include=*.ini --include=*.cfg --include=*.conf --include=*.config --include=*.env --include=*.properties"

PATTERN_DIR="$SKILL_DIR/grep-patterns"
for pattern_file in "$PATTERN_DIR/universal.txt" "$PATTERN_DIR/$JOERN_FRONTEND.txt"; do
  [ -f "$pattern_file" ] || continue
  echo "  Loading $(basename "$pattern_file")"
  while IFS=: read -r focus pattern; do
    [ -z "$focus" ] && continue
    outfile="$PHASE1_DIR/grep-${focus}.txt"
    # shellcheck disable=SC2086
    grep -rniE $GREP_INCLUDES --exclude-dir=.git --exclude-dir=.codereview --exclude-dir=node_modules --exclude-dir=.venv --exclude-dir=vendor --exclude-dir=bin --exclude-dir=obj "$pattern" "$TARGET_ABS" >> "$outfile" 2>/dev/null || true
  done < "$pattern_file"
done

for outfile in "$PHASE1_DIR"/grep-*.txt; do
  [ -f "$outfile" ] || continue
  focus=$(basename "$outfile" .txt | sed 's/^grep-//')
  count=$(wc -l < "$outfile" | tr -d ' ')
  echo "  $focus: $count hits"
done
echo ""

# --- Step 4: Build worklist ---
echo "--- 1d. build-worklist.sh ---"
bash "$SKILL_DIR/build-worklist.sh" "$PHASE1_DIR"
count=$(jq 'length' "$PHASE1_DIR/worklist.json")
echo "Worklist entries: $count"
if [ "$count" -eq 0 ]; then
  echo "ERROR: worklist is empty. No grep hits matched extracted entities." >&2
  echo "Check grep-patterns/ for the target language and verify entities.jsonl has entries." >&2
  exit 1
fi
echo ""

# --- Step 5: Build CLAUDE.md ---
echo "--- 1e. build-claude-md.sh ---"
bash "$SKILL_DIR/build-claude-md.sh" "$PHASE1_DIR" "$WORKDIR" "$PROJECT_ROOT"
echo ""

# --- Step 6: Build PRD.md ---
echo "--- 1f. build-prd.sh ---"
bash "$SKILL_DIR/build-prd.sh" "$PHASE1_DIR" "$WORKDIR" "$PROJECT_ROOT"
checkboxes=$(grep -c '^\- \[ \]' "$WORKDIR/PRD.md" || echo "0")
echo "PRD checkboxes: $checkboxes"
echo ""

# --- Step 7: Repomix ---
echo "--- 1g. repomix pack ---"
REPOMIX_FILE="/tmp/repomix-${TARGET_NAME}.xml"
cd "$PROJECT_ROOT" && npx repomix -o "$REPOMIX_FILE" --quiet "$TARGET_ABS"
echo "Repomix: $REPOMIX_FILE ($(du -h "$REPOMIX_FILE" | cut -f1))"
echo ""

echo "=== Phase 1 complete ==="

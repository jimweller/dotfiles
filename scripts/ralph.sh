#!/usr/bin/env bash
set -euo pipefail

PROMPT_FILE="${1:-.llmtmp/ralph-prompt-external.md}"
MAX_ITER="${MAX_ITER:-100}"
SENTINEL='<promise>ALLDONE</promise>'

if ! command -v claude &>/dev/null; then
  printf "Error: claude not found in PATH.\n" >&2
  exit 1
fi

if ! command -v npx &>/dev/null; then
  printf "Error: npx not found in PATH. Install Node.js.\n" >&2
  exit 1
fi

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  printf "Error: not inside a git repository.\n" >&2
  exit 1
}
cd "$PROJECT_ROOT"

if [[ ! -f "$PROMPT_FILE" ]]; then
  printf "Error: prompt file not found: %s\n" "$PROMPT_FILE" >&2
  exit 1
fi

RUN_TS="$(date +%Y%m%d-%H%M%S)"
RUN_DIR=".llmtmp/ralph-run-${RUN_TS}"
mkdir -p "$RUN_DIR"
STDERR_LOG="$RUN_DIR/run.stderr"
printf "Run logs: %s\n" "$RUN_DIR"

iter=0
while [[ "$iter" -lt "$MAX_ITER" ]]; do
  iter=$(( iter + 1 ))
  JSONL="$RUN_DIR/iter-$(printf '%03d' "$iter").jsonl"
  printf "=== ralph.sh iteration %d/%d (log: %s) ===\n" "$iter" "$MAX_ITER" "$JSONL"

  set +e
  claude --print --verbose --output-format stream-json --dangerously-skip-permissions --model sonnet < "$PROMPT_FILE" 2>>"$STDERR_LOG" \
    | tee "$JSONL" \
    | npx --yes @khanacademy/format-claude-stream
  rc=${PIPESTATUS[0]}
  set -e

  if [[ "$rc" -ne 0 ]]; then
    printf "Warning: claude exited %d on iteration %d (stderr: %s)\n" "$rc" "$iter" "$STDERR_LOG" >&2
  fi

  if grep -qF "$SENTINEL" "$JSONL"; then
    printf "Sentinel found. All tasks complete.\n"
    exit 0
  fi
done

printf "Error: MAX_ITER=%d reached without sentinel. Logs in %s\n" "$MAX_ITER" "$RUN_DIR" >&2
exit 1

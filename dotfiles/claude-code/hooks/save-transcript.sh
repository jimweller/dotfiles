#!/bin/bash
set -euo pipefail

INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')
CWD=$(echo "$INPUT" | jq -r '.cwd')
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name')
REASON=$(echo "$INPUT" | jq -r '.reason // "unknown"')
DATETIME=$(date +"%Y-%m-%d-%H%M%S")
SHORT_ID=$(echo "$SESSION_ID" | cut -c1-8)

OUTPUT_DIR="${CWD}/.llmdocs/transcripts"
HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARSER_SCRIPT="${HOOKS_DIR}/parse-conversation.py"
BASE_NAME="transcript-${DATETIME}-${SHORT_ID}"

[ -f "$TRANSCRIPT_PATH" ] || exit 1
[ -f "$PARSER_SCRIPT" ] || exit 1

mkdir -p "$OUTPUT_DIR"

cp "$TRANSCRIPT_PATH" "${OUTPUT_DIR}/${BASE_NAME}.jsonl"

python3 "$PARSER_SCRIPT" \
    "$TRANSCRIPT_PATH" \
    "${OUTPUT_DIR}/${BASE_NAME}.md" \
    "$SESSION_ID" \
    "$HOOK_EVENT" \
    "$REASON"

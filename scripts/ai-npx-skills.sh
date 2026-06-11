#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="${1:-$SCRIPT_DIR/../manifests/ai-skills.txt}"
AGENTS=(-a claude-code -a codex -a opencode -a hermes-agent)

while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    read -ra args <<< "$line"
    npx -y skills add "${args[@]}" "${AGENTS[@]}" -g -y --copy
done < "$MANIFEST"

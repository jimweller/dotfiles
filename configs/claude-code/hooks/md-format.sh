#!/usr/bin/env bash
# md-format.sh — PostToolUse hook that formats markdown after Edit and Write.
# Reads the Claude Code hook payload on stdin. Requires jq and npx.
#
# Registered twice in settings.json, because an `if` rule matches the tool name
# and `Edit(...)` does not match a Write call:
#   {"matcher":"Edit|Write","hooks":[
#     {"type":"command","if":"Edit(**/*.md)","command":"~/.claude/hooks/md-format.sh"},
#     {"type":"command","if":"Write(**/*.md)","command":"~/.claude/hooks/md-format.sh"}]}
#
# markdownlint runs before prettier. The reverse order leaves MD022 unfixed on a
# heading written without a space (#Title) and needs a second pass to converge.
#
# A rewrite invalidates the model's in-context copy of the file, so the hook
# reports it through additionalContext. Two Edit calls to one file in a single
# assistant turn still lose the second call to a string mismatch; the model
# recovers by re-reading.

set -euo pipefail

MDLINT_CONFIG="$HOME/.config/markdownlint/.markdownlint-cli2.jsonc"
PRETTIER_CONFIG="$HOME/.prettierrc"

INPUT="$(cat)"
FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')"

[[ -n "$FILE" ]] || exit 0
[[ -f "$FILE" ]] || exit 0
[[ "$FILE" == *.md ]] || exit 0

# Agent artifacts, matching the exclusions in ~/.claude/rules/md-syntax.md.
case "$FILE" in
    */.llmtmp/*|*/.llmdocs/*|*/SKILL.md|"$HOME"/.claude/plans/*) exit 0 ;;
esac

BEFORE="$(shasum -a 256 "$FILE" | cut -d' ' -f1)"

LINT_FIX_CLEAN=1
if ! npx -y markdownlint-cli2 --config "$MDLINT_CONFIG" --fix "$FILE" >/dev/null 2>&1; then
    LINT_FIX_CLEAN=0
fi

if ! PRETTIER_ERR="$(npx -y prettier --config "$PRETTIER_CONFIG" --write "$FILE" 2>&1 >/dev/null)"; then
    printf 'md-format: prettier failed on %s\n%s\n' "$FILE" "$PRETTIER_ERR" >&2
    exit 2
fi

AFTER="$(shasum -a 256 "$FILE" | cut -d' ' -f1)"

STALE=""
if [[ "$BEFORE" != "$AFTER" ]]; then
    STALE="md-format reformatted $FILE. The in-context copy is stale. Re-read the file before editing it again."
fi

# The --fix run reports what it could not repair. Prettier may have repaired it
# since, so re-check only when something was left over.
if [[ "$LINT_FIX_CLEAN" -eq 0 ]]; then
    if ! RESIDUAL="$(npx -y markdownlint-cli2 --config "$MDLINT_CONFIG" "$FILE" 2>&1)"; then
        printf 'md-format: markdownlint reports issues it cannot fix in %s\n%s\n' "$FILE" "$RESIDUAL" >&2
        if [[ -n "$STALE" ]]; then
            printf '%s\n' "$STALE" >&2
        fi
        exit 2
    fi
fi

if [[ -n "$STALE" ]]; then
    jq -nc --arg msg "$STALE" \
        '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$msg}}'
fi

exit 0

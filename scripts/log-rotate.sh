#!/usr/bin/env bash
# Cap every log under ~/.logs at a fixed size, keeping the most recent bytes.
#
# Truncates in place rather than renaming. launchd holds StandardOutPath and
# StandardErrorPath open for the whole life of each agent, so a rename would
# leave launchd appending to the rotated copy forever while the active path
# stayed empty. Rewriting the same inode keeps those descriptors valid.
#
# Env:
#   DOTFILES_LOG_DIR         directory to scan (default ~/.logs)
#   DOTFILES_LOG_MAX_BYTES   rotate once a file exceeds this (default 10 MiB)
#   DOTFILES_LOG_KEEP_BYTES  bytes of tail retained (default 2 MiB)

set -euo pipefail

LOG_DIR="${DOTFILES_LOG_DIR:-$HOME/.logs}"
MAX_BYTES="${DOTFILES_LOG_MAX_BYTES:-10485760}"
KEEP_BYTES="${DOTFILES_LOG_KEEP_BYTES:-2097152}"

[[ -d "$LOG_DIR" ]] || exit 0

file_size() {
    stat -f '%z' "$1" 2>/dev/null || stat -c '%s' "$1"
}

shopt -s nullglob
rotated=0
reclaimed=0

for f in "$LOG_DIR"/*.log "$LOG_DIR"/*.txt "$LOG_DIR"/*.err; do
    [[ -f "$f" ]] || continue

    size="$(file_size "$f")"
    (( size > MAX_BYTES )) || continue

    tmp="$(mktemp)"
    tail -c "$KEEP_BYTES" "$f" > "$tmp"
    {
        printf '=== rotated %s: kept last %s of %s bytes ===\n' \
            "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$KEEP_BYTES" "$size"
        cat "$tmp"
    } > "$f"
    rm -f "$tmp"

    new_size="$(file_size "$f")"
    printf 'rotated %s: %s -> %s bytes\n' "$f" "$size" "$new_size"
    rotated=$(( rotated + 1 ))
    reclaimed=$(( reclaimed + size - new_size ))
done

printf 'log-rotate: %s file(s) rotated, %s MiB reclaimed\n' \
    "$rotated" "$(( reclaimed / 1048576 ))"

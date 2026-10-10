#!/usr/bin/env bash
# Tests for the conversion step of scripts/confluence-backup.sh. Plain bash, no framework.
# Each case runs a copy of the real script with a stub sops and a stub exporter that
# copies fixture pages, so no secret is decrypted and Confluence is never called.
# pandoc is real.

set -uo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/confluence-backup.sh"
TMP_ROOT="$(mktemp -d /tmp/cbt.XXXXXX)"
PIXEL_PNG_B64='iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='

cleanup() { chmod -R u+w "$TMP_ROOT"; command -p rm -rf "$TMP_ROOT"; }
trap cleanup EXIT

pass() { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; shift; for line in "$@"; do printf '     %s\n' "$line"; done; }
assert_eq() {
    if [[ "$2" == "$3" ]]; then pass "$1"; else fail "$1" "expected: $2" "actual:   $3"; fi
}
assert_contains() {
    if [[ "$3" == *"$2"* ]]; then pass "$1"; else fail "$1" "missing: $2" "in: $3"; fi
}
assert_not_contains() {
    if [[ "$3" != *"$2"* ]]; then pass "$1"; else fail "$1" "unexpected: $2" "in: $3"; fi
}

# Builds one isolated world with a stub sops on PATH and a stub exporter beside the
# script copy. Paths carry spaces to catch quoting bugs.
new_world() {
    W="$(mktemp -d "$TMP_ROOT/w.XXXXXX")"
    FIXTURES="$W/fixtures"
    OUT="$W/out dir"
    mkdir -p "$W/bin" "$W/scripts" "$FIXTURES"
    cp "$SCRIPT" "$W/scripts/confluence-backup.sh"
    printf '#!/usr/bin/env bash\ncat "${@: -1}"\n' > "$W/bin/sops"
    printf '#!/usr/bin/env bash\nmkdir -p "${@: -1}"\ncp -R "$FIXTURE_DIR/." "${@: -1}/"\n' \
        > "$W/scripts/confluence-export.py"
    chmod +x "$W/bin/sops" "$W/scripts/confluence-export.py"
    : > "$W/config.enc.yaml"
    : > "$W/env.enc.env"
}

# add_page <relative page dir> <body html>
add_page() {
    mkdir -p "$FIXTURES/$1"
    printf '<!DOCTYPE html>\n<html><head><meta charset="utf-8"><title>%s</title></head>\n<body>\n%s\n</body></html>\n' \
        "$(basename "$1")" "$2" > "$FIXTURES/$1/index.html"
}

# Makes pandoc fail on a page by leaving its output directory read-only.
lock_output() {
    mkdir -p "$OUT/$1"
    chmod 555 "$OUT/$1"
}

add_pixel() {
    mkdir -p "$FIXTURES/$1/attachments"
    printf '%s' "$PIXEL_PNG_B64" | base64 --decode > "$FIXTURES/$1/attachments/pixel.png"
}

run_backup() {
    RUN_OUT="$(PATH="$W/bin:$PATH" FIXTURE_DIR="$FIXTURES" \
        CONFLUENCE_CONFIG="$W/config.enc.yaml" CONFLUENCE_ENV="$W/env.enc.env" \
        "$W/scripts/confluence-backup.sh" "$OUT" 2>&1)"
    RUN_RC=$?
}

test_server_relative_avatar_is_dropped() {
    new_world
    add_page "DEV/Team Home" '<p>Team page</p>
<img class="userLogo logo" src="/wiki/aa-avatar/712020:d2573b6c" alt="User icon: someone" title="someone" />'
    run_backup
    assert_eq "avatar page: exit status" "0" "$RUN_RC"
    assert_contains "avatar page: reported converted" "✓ DEV/Team Home/index.html" "$RUN_OUT"
    local html
    html="$(cat "$OUT/DEV/Team Home/index.html" 2>/dev/null)"
    assert_contains "avatar page: body kept" "Team page" "$html"
    assert_not_contains "avatar page: avatar dropped" "/wiki/aa-avatar" "$html"
}

test_relative_attachment_is_embedded() {
    new_world
    add_page "DEV/With Image" '<p>Diagram</p><img src="attachments/pixel.png" alt="pixel" />'
    add_pixel "DEV/With Image"
    run_backup
    assert_eq "attachment page: exit status" "0" "$RUN_RC"
    assert_contains "attachment page: image embedded" "data:image/png;base64" \
        "$(cat "$OUT/DEV/With Image/index.html" 2>/dev/null)"
}

test_failed_conversion_logs_pandoc_error() {
    new_world
    add_page "DEV/Broken" '<p>Broken page</p>'
    lock_output "DEV/Broken"
    run_backup
    assert_eq "broken page: exit status" "1" "$RUN_RC"
    assert_contains "broken page: reported failed" "✗ Failed" "$RUN_OUT"
    assert_contains "broken page: pandoc error logged" "ermission denied" "$RUN_OUT"
}

test_stale_output_does_not_mask_failure() {
    new_world
    add_page "DEV/Broken" '<p>Broken page</p>'
    mkdir -p "$OUT/DEV/Broken"
    printf 'converted on an earlier night\n' > "$OUT/DEV/Broken/index.html"
    chmod 444 "$OUT/DEV/Broken/index.html"
    lock_output "DEV/Broken"
    run_backup
    assert_eq "stale output: exit status" "1" "$RUN_RC"
    assert_contains "stale output: reported failed" "✗ Failed" "$RUN_OUT"
    assert_not_contains "stale output: not reported converted" "✓ DEV/Broken" "$RUN_OUT"
}

test_failure_does_not_stop_other_pages() {
    new_world
    add_page "DEV/Broken" '<p>Broken page</p>'
    lock_output "DEV/Broken"
    add_page "DEV/Fine" '<p>Fine page</p>'
    run_backup
    assert_eq "mixed run: exit status" "1" "$RUN_RC"
    assert_contains "mixed run: summary counts both" "Summary: 1/2 successful" "$RUN_OUT"
    assert_contains "mixed run: good page converted" "Fine page" \
        "$(cat "$OUT/DEV/Fine/index.html" 2>/dev/null)"
}

RESULTS="$TMP_ROOT/results.txt"
: > "$RESULTS"
for t in $(declare -F | awk '{print $3}' | grep '^test_'); do
    out="$( ( "$t" ) 2>&1 )"
    if ! grep -qE '^(ok|FAIL) ' <<< "$out"; then
        out="$(printf 'FAIL %s produced no assertions\n%s' "$t" "$out")"
    fi
    printf '%s\n' "$out" >> "$RESULTS"
done

cat "$RESULTS"
PASS=$(grep -c '^ok ' "$RESULTS")
FAIL=$(grep -c '^FAIL ' "$RESULTS")
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[[ $FAIL -eq 0 && $PASS -gt 0 ]]

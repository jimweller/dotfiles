#!/usr/bin/env bash
# Tests for scripts/keys.sh. Plain bash, no framework.
# Every case runs against a throwaway age key, HOME, GNUPGHOME, and repo copy,
# so the operator's real keys are never read or written.

set -uo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/keys.sh"
TMP_ROOT="$(mktemp -d /tmp/kt.XXXXXX)"

cleanup() {
    local g
    for g in "$TMP_ROOT"/*/gnupg*; do
        [[ -d "$g" ]] && GNUPGHOME="$g" gpgconf --kill gpg-agent >/dev/null 2>&1
    done
    command -p rm -rf "$TMP_ROOT"
}
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
assert_same_file() {
    if cmp -s "$2" "$3"; then pass "$1"; else fail "$1" "differs: $2 vs $3"; fi
}
mode_of() { find "$1" -maxdepth 0 -perm "$2" | wc -l | tr -d ' '; }

# Builds one isolated world and exports the variables keys.sh reads.
# The world has a repo dir with a space in its name to catch quoting bugs.
new_world() {
    W="$(mktemp -d "$TMP_ROOT/w.XXXXXX")"
    export HOME="$W/home"
    export DOTFILES_DIR="$W/dot files"
    export GNUPGHOME="$W/gnupg"
    export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
    mkdir -p "$HOME/.ssh" "$DOTFILES_DIR" "$GNUPGHOME" "$(dirname "$SOPS_AGE_KEY_FILE")"
    chmod 700 "$GNUPGHOME"
    age-keygen -o "$W/age.txt" 2>"$W/age.pub"
    AGE_SECRET="$(grep '^AGE-SECRET-KEY-' "$W/age.txt")"
    AGE_RECIPIENT="$(sed -n 's/^Public key: //p' "$W/age.pub")"
    printf 'creation_rules:\n  - age: %s\n' "$AGE_RECIPIENT" > "$DOTFILES_DIR/.sops.yaml"
    printf '%s\n' "$AGE_SECRET" > "$SOPS_AGE_KEY_FILE"
    chmod 600 "$SOPS_AGE_KEY_FILE"
}

seed_ssh() {
    printf 'PRIVATE-KEY-ALPHA\n' > "$HOME/.ssh/id_alpha"
    printf 'ssh-ed25519 AAAA alpha@example.com\n' > "$HOME/.ssh/id_alpha.pub"
    printf 'PRIVATE-KEY-BETA-NO-PUB' > "$HOME/.ssh/id_beta"
    printf 'alpha@example.com ssh-ed25519 AAAA\n' > "$HOME/.ssh/allowed_signers"
    printf 'Host *\n' > "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/id_alpha" "$HOME/.ssh/id_beta"
}

seed_gpg() {
    gpg --batch --quiet --passphrase '' --quick-gen-key 'Test Key <test@example.com>' default default never >/dev/null 2>&1
    GPG_FPR="$(gpg --list-secret-keys --with-colons | awk -F: '/^fpr/ {print $10; exit}')"
}

ks() { "$BASH" "$SCRIPT" "$@"; }

# Moves the world to a fresh HOME and GNUPGHOME that share the same repo and age key.
fresh_machine() {
    local old_key="$SOPS_AGE_KEY_FILE"
    export HOME="$W/home2"
    export GNUPGHOME="$W/gnupg2"
    export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
    mkdir -p "$(dirname "$SOPS_AGE_KEY_FILE")" "$GNUPGHOME"
    chmod 700 "$GNUPGHOME"
    cp "$old_key" "$SOPS_AGE_KEY_FILE"
}

# --- init -------------------------------------------------------------------

test_init_writes_missing_key() {
    new_world
    command -p rm -f "$SOPS_AGE_KEY_FILE"
    DOTFILES_KEY="$AGE_SECRET" ks init >/dev/null
    assert_eq "init writes the age key when none exists" "$AGE_SECRET" "$(grep '^AGE-SECRET-KEY-' "$SOPS_AGE_KEY_FILE")"
    assert_eq "init writes the key file with mode 600" "1" "$(mode_of "$SOPS_AGE_KEY_FILE" 600)"
}

test_init_keeps_other_identities() {
    new_world
    age-keygen -o "$W/other.txt" 2>/dev/null
    local other; other="$(grep '^AGE-SECRET-KEY-' "$W/other.txt")"
    printf '# other repo\n%s\n' "$other" > "$SOPS_AGE_KEY_FILE"
    DOTFILES_KEY="$AGE_SECRET" ks init >/dev/null
    local content; content="$(cat "$SOPS_AGE_KEY_FILE")"
    assert_contains "init keeps an existing different identity" "$other" "$content"
    assert_contains "init adds the dotfiles identity beside it" "$AGE_SECRET" "$content"
}

test_init_unchanged_when_present() {
    new_world
    local before; before="$(cat "$SOPS_AGE_KEY_FILE")"
    DOTFILES_KEY="$AGE_SECRET" ks init >/dev/null
    assert_eq "init leaves a key file that already holds the key" "$before" "$(cat "$SOPS_AGE_KEY_FILE")"
}

test_init_rejects_bad_input() {
    new_world
    local rc
    DOTFILES_KEY="" ks init >/dev/null 2>&1; rc=$?
    assert_eq "init exits 2 when DOTFILES_KEY is empty" "2" "$rc"
    DOTFILES_KEY="not-an-age-key" ks init >/dev/null 2>&1; rc=$?
    assert_eq "init exits 2 when DOTFILES_KEY is not an age secret key" "2" "$rc"
}

# --- save -------------------------------------------------------------------

test_save_encrypts_ssh_files() {
    new_world; seed_ssh
    ks save >/dev/null
    local k="$DOTFILES_DIR/configs/keys/ssh"
    local n
    for n in id_alpha id_alpha.pub id_beta allowed_signers; do
        if [[ -f "$k/$n.sops.json" ]]; then pass "save writes ssh/$n.sops.json"; else fail "save writes ssh/$n.sops.json"; fi
    done
    if [[ -e "$k/config.sops.json" ]]; then fail "save leaves out ~/.ssh/config"; else pass "save leaves out ~/.ssh/config"; fi
    assert_not_contains "save writes no plaintext key material" "PRIVATE-KEY-ALPHA" "$(cat "$k"/*.sops.json)"
}

test_save_is_idempotent() {
    new_world; seed_ssh; seed_gpg
    ks save >/dev/null
    sleep 1
    local before; before="$(cd "$DOTFILES_DIR" && find configs/keys -type f -exec shasum {} + | sort)"
    ks save >/dev/null
    assert_eq "save leaves unchanged keys byte-identical on disk" "$before" "$(cd "$DOTFILES_DIR" && find configs/keys -type f -exec shasum {} + | sort)"
}

test_save_rewrites_only_changed() {
    new_world; seed_ssh
    ks save >/dev/null
    local k="$DOTFILES_DIR/configs/keys/ssh"
    local beta_before; beta_before="$(shasum "$k/id_beta.sops.json")"
    local alpha_before; alpha_before="$(shasum "$k/id_alpha.sops.json")"
    printf 'PRIVATE-KEY-ALPHA-ROTATED\n' > "$HOME/.ssh/id_alpha"
    local out; out="$(ks save)"
    assert_eq "save keeps an unchanged key's file" "$beta_before" "$(shasum "$k/id_beta.sops.json")"
    if [[ "$alpha_before" != "$(shasum "$k/id_alpha.sops.json")" ]]; then pass "save rewrites a changed key"; else fail "save rewrites a changed key"; fi
    assert_contains "save reports the changed key" "id_alpha" "$out"
}

test_save_reports_stale_without_deleting() {
    new_world; seed_ssh
    ks save >/dev/null
    command -p rm "$HOME/.ssh/id_beta"
    local out; out="$(ks save 2>&1)"
    assert_contains "save reports a key missing from this machine" "id_beta" "$out"
    if [[ -f "$DOTFILES_DIR/configs/keys/ssh/id_beta.sops.json" ]]; then pass "save keeps the repo copy of a missing key"; else fail "save keeps the repo copy of a missing key"; fi
}

test_save_exports_gpg() {
    new_world; seed_ssh; seed_gpg
    ks save >/dev/null
    local g="$DOTFILES_DIR/configs/keys/gnupg"
    local n
    for n in pubkeys.asc.sops.json ownertrust.txt.sops.json; do
        if [[ -f "$g/$n" ]]; then pass "save writes gnupg/$n"; else fail "save writes gnupg/$n"; fi
    done
    assert_eq "save writes the gpg private key files" \
        "$(find "$GNUPGHOME/private-keys-v1.d" -type f -name '*.key' | wc -l | tr -d ' ')" \
        "$(find "$g/private-keys-v1.d" -type f -name '*.key.sops.json' | wc -l | tr -d ' ')"
    assert_eq "save writes the gpg revocation certificates" \
        "$(find "$GNUPGHOME/openpgp-revocs.d" -type f -name '*.rev' | wc -l | tr -d ' ')" \
        "$(find "$g/openpgp-revocs.d" -type f -name '*.rev.sops.json' | wc -l | tr -d ' ')"
}

# --- restore ----------------------------------------------------------------

test_restore_fresh_machine() {
    new_world; seed_ssh
    ks save >/dev/null
    local src="$HOME/.ssh"
    fresh_machine
    ks restore >/dev/null
    local n
    for n in id_alpha id_alpha.pub id_beta allowed_signers; do
        assert_same_file "restore writes ~/.ssh/$n byte-identical" "$src/$n" "$HOME/.ssh/$n"
    done
    assert_eq "restore makes ~/.ssh mode 700" "1" "$(mode_of "$HOME/.ssh" 700)"
    assert_eq "restore makes a private key mode 600" "1" "$(mode_of "$HOME/.ssh/id_alpha" 600)"
    assert_eq "restore makes a public key mode 644" "1" "$(mode_of "$HOME/.ssh/id_alpha.pub" 644)"
    assert_eq "restore makes allowed_signers mode 644" "1" "$(mode_of "$HOME/.ssh/allowed_signers" 644)"
}

test_restore_overwrites_different() {
    new_world; seed_ssh
    ks save >/dev/null
    local src="$W/expected"; cp "$HOME/.ssh/id_alpha" "$src"
    printf 'LOCAL-DIFFERENT\n' > "$HOME/.ssh/id_alpha"
    local out; out="$(ks restore)"
    assert_same_file "restore overwrites a file that differs" "$src" "$HOME/.ssh/id_alpha"
    assert_contains "restore reports the overwritten file" "id_alpha" "$out"
}

test_restore_leaves_identical() {
    new_world; seed_ssh
    ks save >/dev/null
    touch -t 202001010000 "$HOME/.ssh/id_beta"
    ks restore >/dev/null
    assert_eq "restore leaves an identical file untouched" "1" "$(find "$HOME/.ssh/id_beta" ! -newermt '2020-01-02' | wc -l | tr -d ' ')"
}

test_restore_without_age_key() {
    new_world; seed_ssh
    ks save >/dev/null
    command -p rm -f "$SOPS_AGE_KEY_FILE"
    local rc out
    out="$(ks restore 2>&1)"; rc=$?
    assert_eq "restore exits 2 without an age key" "2" "$rc"
    assert_contains "restore names the missing age key file" "$SOPS_AGE_KEY_FILE" "$out"
}

test_restore_gpg_fresh_machine() {
    new_world; seed_ssh; seed_gpg
    ks save >/dev/null
    local fpr="$GPG_FPR"
    fresh_machine
    ks restore >/dev/null 2>&1
    assert_contains "restore makes the gpg secret key usable" "$fpr" "$(gpg --list-secret-keys --with-colons 2>/dev/null)"
    assert_contains "restore brings back ownertrust" "$fpr:6:" "$(gpg --export-ownertrust 2>/dev/null)"
    assert_eq "restore makes GNUPGHOME mode 700" "1" "$(mode_of "$GNUPGHOME" 700)"
}

test_restore_without_gpg_binary() {
    new_world; seed_ssh; seed_gpg
    ks save >/dev/null
    fresh_machine
    local rc out
    out="$(KEYS_GPG=/nonexistent/gpg ks restore 2>&1)"; rc=$?
    assert_eq "restore still exits 0 when gpg is missing" "0" "$rc"
    assert_contains "restore says the gpg keys were not restored" "gpg" "$out"
    if [[ -f "$HOME/.ssh/id_alpha" ]]; then pass "restore still writes ssh keys when gpg is missing"; else fail "restore still writes ssh keys when gpg is missing"; fi
}

test_no_plaintext_in_trash() {
    new_world; seed_ssh; seed_gpg
    ks save >/dev/null
    fresh_machine
    ks restore >/dev/null 2>&1
    local trashed
    trashed="$(find "$W" -path '*Trash*' -type f 2>/dev/null | wc -l | tr -d ' ')"
    assert_eq "save and restore leave no decrypted file in a Trash folder" "0" "$trashed"
}

# --- usage ------------------------------------------------------------------

test_usage() {
    new_world
    local rc
    ks >/dev/null 2>&1; rc=$?
    assert_eq "no command exits 2" "2" "$rc"
    ks bogus >/dev/null 2>&1; rc=$?
    assert_eq "unknown command exits 2" "2" "$rc"
}

# Each case runs in a subshell so its exported world stays local to it. A case that
# prints no assertion at all crashed before reaching one, and counts as a failure.
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

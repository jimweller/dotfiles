#!/usr/bin/env bash
# SSH and GPG key material, kept as SOPS-encrypted files under configs/keys/ and
# decrypted with the same age key as configs/secrets/.
#
# Commands:
#   init      Add DOTFILES_KEY, the age secret key, to the age key file. Run once on a
#             new machine, before ./install.
#   save      Encrypt ~/.ssh/id*, ~/.ssh/allowed_signers, the GPG private keys and
#             revocation certificates, and an export of the GPG public keys and
#             ownertrust into configs/keys/. An unchanged file keeps its ciphertext. A
#             file gone from this machine is reported and kept.
#   restore   Decrypt configs/keys/ into ~/.ssh and GNUPGHOME, overwriting any file that
#             differs, then import the GPG public keys and ownertrust.
#
# Environment: DOTFILES_DIR (repo root), SOPS_AGE_KEY_FILE, GNUPGHOME, KEYS_GPG (the gpg
# binary). Exit 2 means a usage error or a missing age key.
# Written for bash 3.2, which is what macOS ships as /bin/bash.

set -euo pipefail
umask 077

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
KEYS_DIR="$DOTFILES_DIR/configs/keys"
export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"
GNUPG_DIR="${GNUPGHOME:-$HOME/.gnupg}"
export GNUPGHOME="$GNUPG_DIR"
GPG="${KEYS_GPG:-gpg}"
AGE_KEY_RE='^AGE-SECRET-KEY-1[0-9A-Z]+$'

die() { printf 'keys: %s\n' "$1" >&2; exit 2; }

WORK="$(mktemp -d)"
# command -p skips the safe-rm wrapper on PATH (scripts/rm), which would move
# decrypted key material into the Trash instead of deleting it.
trap 'command -p rm -rf "$WORK"' EXIT

require_sops() { command -v sops >/dev/null 2>&1 || die "sops not found in PATH"; }

require_age_key() {
    [[ -r "$SOPS_AGE_KEY_FILE" ]] \
        || die "no age key at $SOPS_AGE_KEY_FILE. Set DOTFILES_KEY and run scripts/keys.sh init"
}

encrypt_to() {
    sops --config "$DOTFILES_DIR/.sops.yaml" encrypt --input-type binary --output-type json "$1" > "$2"
}

decrypt_to() {
    sops decrypt --input-type json --output-type binary "$1" > "$2"
}

have_gpg() { command -v "$GPG" >/dev/null 2>&1; }

# Fingerprints of every key this keyring holds a secret part for, one per line.
secret_fingerprints() {
    "$GPG" --batch --list-secret-keys --with-colons 2>/dev/null \
        | awk -F: '$1 == "sec" { want = 1; next } want && $1 == "fpr" { print $10; want = 0 }'
}

# --- init -------------------------------------------------------------------

cmd_init() {
    local key="${DOTFILES_KEY:-}" dir
    [[ -n "$key" ]] || die "DOTFILES_KEY is not set"
    [[ "$key" =~ $AGE_KEY_RE ]] || die "DOTFILES_KEY is not an age secret key"
    dir="$(dirname "$SOPS_AGE_KEY_FILE")"
    mkdir -p "$dir"
    chmod 700 "$dir"
    if [[ -f "$SOPS_AGE_KEY_FILE" ]] && grep -qxF "$key" "$SOPS_AGE_KEY_FILE"; then
        printf 'age key already in %s\n' "$SOPS_AGE_KEY_FILE"
        return
    fi
    # Append so any identity another repo put in the file survives.
    if [[ -s "$SOPS_AGE_KEY_FILE" && -n "$(tail -c 1 "$SOPS_AGE_KEY_FILE")" ]]; then
        printf '\n' >> "$SOPS_AGE_KEY_FILE"
    fi
    printf '%s\n' "$key" >> "$SOPS_AGE_KEY_FILE"
    chmod 600 "$SOPS_AGE_KEY_FILE"
    printf 'added the age key to %s\n' "$SOPS_AGE_KEY_FILE"
}

# --- save -------------------------------------------------------------------

SAVED=0
UNCHANGED=0

save_one() {
    local src="$1" rel="$2" dest="$KEYS_DIR/$2.sops.json"
    printf '%s\n' "$rel" >> "$WORK/seen"
    mkdir -p "$(dirname "$dest")"
    if [[ -f "$dest" ]] && decrypt_to "$dest" "$WORK/current" 2>/dev/null && cmp -s "$src" "$WORK/current"; then
        UNCHANGED=$((UNCHANGED + 1))
        return
    fi
    encrypt_to "$src" "$WORK/new"
    cat "$WORK/new" > "$dest"
    SAVED=$((SAVED + 1))
    printf 'saved %s\n' "$rel"
}

save_glob() {
    local dir="$1" pattern="$2" prefix="$3" f
    for f in "$dir"/$pattern; do
        [[ -f "$f" && ! -L "$f" ]] || continue
        save_one "$f" "$prefix/$(basename "$f")"
    done
}

cmd_save() {
    require_sops
    require_age_key
    [[ -f "$DOTFILES_DIR/.sops.yaml" ]] || die "no .sops.yaml in $DOTFILES_DIR"
    : > "$WORK/seen"

    save_glob "$HOME/.ssh" 'id*' ssh
    if [[ -f "$HOME/.ssh/allowed_signers" ]]; then
        save_one "$HOME/.ssh/allowed_signers" ssh/allowed_signers
    fi

    if [[ -d "$GNUPG_DIR" ]]; then
        have_gpg || die "$GPG not found, so the GPG keys in $GNUPG_DIR cannot be exported"
        save_glob "$GNUPG_DIR/private-keys-v1.d" '*.key' gnupg/private-keys-v1.d
        save_glob "$GNUPG_DIR/openpgp-revocs.d" '*.rev' gnupg/openpgp-revocs.d
        local fprs
        fprs="$(secret_fingerprints)"
        if [[ -n "$fprs" ]]; then
            # shellcheck disable=SC2086 # one argument per fingerprint
            "$GPG" --batch --armor --export $fprs > "$WORK/pubkeys.asc"
            # The export opens with a comment stamped with the current time. Dropping
            # comments keeps the content stable, so an unchanged trust db saves nothing.
            "$GPG" --batch --export-ownertrust | sed '/^#/d' > "$WORK/ownertrust.txt"
            save_one "$WORK/pubkeys.asc" gnupg/pubkeys.asc
            save_one "$WORK/ownertrust.txt" gnupg/ownertrust.txt
        fi
    fi

    local enc rel
    if [[ -d "$KEYS_DIR" ]]; then
        while IFS= read -r enc; do
            rel="${enc#"$KEYS_DIR"/}"
            rel="${rel%.sops.json}"
            if ! grep -qxF "$rel" "$WORK/seen"; then
                printf 'kept %s, not on this machine\n' "$rel"
            fi
        done < <(find "$KEYS_DIR" -type f -name '*.sops.json' | sort)
    fi
    printf '%d saved, %d unchanged\n' "$SAVED" "$UNCHANGED"
}

# --- restore ----------------------------------------------------------------

WROTE=0
SAME=0

restore_one() {
    local enc="$1" dest="$2" mode="$3"
    decrypt_to "$enc" "$WORK/plain"
    if [[ -f "$dest" ]] && cmp -s "$WORK/plain" "$dest"; then
        chmod "$mode" "$dest"
        SAME=$((SAME + 1))
        return
    fi
    cat "$WORK/plain" > "$dest"
    chmod "$mode" "$dest"
    WROTE=$((WROTE + 1))
    printf 'restored %s\n' "$dest"
}

restore_dir() {
    local src="$1" dest="$2" enc
    mkdir -p "$dest"
    chmod 700 "$dest"
    for enc in "$src"/*.sops.json; do
        [[ -f "$enc" ]] || continue
        restore_one "$enc" "$dest/$(basename "$enc" .sops.json)" 600
    done
}

cmd_restore() {
    require_sops
    require_age_key
    [[ -d "$KEYS_DIR" ]] || die "no keys in $KEYS_DIR"

    local enc name mode
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    for enc in "$KEYS_DIR"/ssh/*.sops.json; do
        [[ -f "$enc" ]] || continue
        name="$(basename "$enc" .sops.json)"
        case "$name" in
            *.pub | allowed_signers) mode=644 ;;
            *) mode=600 ;;
        esac
        restore_one "$enc" "$HOME/.ssh/$name" "$mode"
    done

    if [[ -d "$KEYS_DIR/gnupg" ]]; then
        if ! have_gpg; then
            printf 'keys: %s not found, GPG keys not restored\n' "$GPG" >&2
        else
            mkdir -p "$GNUPG_DIR"
            chmod 700 "$GNUPG_DIR"
            restore_dir "$KEYS_DIR/gnupg/private-keys-v1.d" "$GNUPG_DIR/private-keys-v1.d"
            restore_dir "$KEYS_DIR/gnupg/openpgp-revocs.d" "$GNUPG_DIR/openpgp-revocs.d"
            if [[ -f "$KEYS_DIR/gnupg/pubkeys.asc.sops.json" ]]; then
                decrypt_to "$KEYS_DIR/gnupg/pubkeys.asc.sops.json" "$WORK/pubkeys.asc"
                "$GPG" --batch --quiet --import "$WORK/pubkeys.asc"
            fi
            if [[ -f "$KEYS_DIR/gnupg/ownertrust.txt.sops.json" ]]; then
                decrypt_to "$KEYS_DIR/gnupg/ownertrust.txt.sops.json" "$WORK/ownertrust.txt"
                "$GPG" --batch --quiet --import-ownertrust "$WORK/ownertrust.txt"
            fi
        fi
    fi
    printf '%d restored, %d unchanged\n' "$WROTE" "$SAME"
}

[[ $# -ge 1 ]] || die "usage: keys.sh <init|save|restore>"
case "$1" in
    init) cmd_init ;;
    save) cmd_save ;;
    restore) cmd_restore ;;
    *) die "unknown command: $1, expected init, save, or restore" ;;
esac

#!/bin/bash

MODE="$1"
PASSWORD="$2"
ARCHIVE="${3:-$HOME/Projects/personal/dotfiles/manifests/zcnqj7nbbgg4szrm.gpg}"
TMPFILE=$(mktemp)

if [[ "$MODE" != "open" && "$MODE" != "save" ]]; then
  echo "Usage: $0 [open|save] [password] [archive_file]"
  exit 1
fi

if [ -z "$PASSWORD" ]; then
  printf "Enter passphrase: "
  read -s PASSWORD
  echo
fi

FILE_PATTERNS=(
  "$HOME/.ssh/id*"
  "$HOME/.ssh/allowed_signers"
  "$HOME/.secrets/*.env"
)

FILES=$(find ${FILE_PATTERNS[@]} -type f 2>/dev/null)

if [ "$MODE" = "open" ]; then
  while true; do
    if echo "$PASSWORD" | gpg --decrypt --pinentry-mode loopback --passphrase-fd 0 "$ARCHIVE" > "$TMPFILE" ; then
      if tar xvz -C "$HOME" -f "$TMPFILE"; then
        for pattern in "${FILE_PATTERNS[@]}"; do
          chmod 600 $pattern 2>/dev/null
        done
        rm -f "$TMPFILE"
        break
      fi
    fi
    echo "Incorrect passphrase or extraction failed, try again."
    printf "Enter passphrase: "
    read -s PASSWORD
    echo
  done

elif [ "$MODE" = "save" ]; then
  tar --disable-copyfile --no-xattrs -cvzf - \
    -C "$HOME" $(echo "$FILES" | sed "s|$HOME/||g") \
    | gpg --batch --yes --passphrase "$PASSWORD" --symmetric --cipher-algo AES256 -o "$ARCHIVE"
fi

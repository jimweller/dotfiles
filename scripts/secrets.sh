#!/bin/bash

MODE="$1"

# Environment variables (DOTFILES_KEY, DOTFILES_ARCHIVE) should be passed from host
# via docker --env flags rather than sourcing local files in container

# Set password - use parameter if provided, otherwise use DOTFILES_KEY
if [ -n "$2" ]; then
  PASSWORD="$2"
elif [ -n "$DOTFILES_KEY" ]; then
  PASSWORD="$DOTFILES_KEY"
fi

# Set archive - use parameter if provided, otherwise use DOTFILES_ARCHIVE, otherwise use default
if [ -n "$3" ]; then
  ARCHIVE="$3"
elif [ -n "$DOTFILES_ARCHIVE" ]; then
  ARCHIVE="$(eval echo "$DOTFILES_ARCHIVE")"
else
  ARCHIVE="$HOME/dotfiles/manifests/zcnqj7nbbgg4szrm.gpg"
fi


TMPFILE=$(mktemp)

if [[ "$MODE" != "open" && "$MODE" != "save" && "$MODE" != "list" ]]; then
  echo "Usage: $0 [open|save|list] [password] [archive_file]"
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
    
elif [ "$MODE" = "list" ]; then
  while true; do
    if echo "$PASSWORD" | gpg --decrypt --pinentry-mode loopback --passphrase-fd 0 "$ARCHIVE" > "$TMPFILE" ; then
      echo "Contents of encrypted archive:"
      tar -tzf "$TMPFILE"
      rm -f "$TMPFILE"
      break
    fi
    echo "Incorrect passphrase, try again."
    printf "Enter passphrase: "
    read -s PASSWORD
    echo
  done
fi

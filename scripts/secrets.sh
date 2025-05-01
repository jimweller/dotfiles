#!/bin/bash

if [ ! -f "$HOME/.git-credentials-work" ]; then
  while true; do
    printf "Enter passphrase to decrypt secrets: "
    read -s GPG_PASS
    echo

    TMPFILE=$(mktemp)

    if echo "$GPG_PASS" | gpg --decrypt --pinentry-mode loopback --passphrase-fd 0 ~/.dotfiles/manifests/zcnqj7nbbgg4szrm.gpg > "$TMPFILE" 2>/dev/null; then
      if tar xz -C "$HOME" -f "$TMPFILE"; then
        chmod 600 ~/.git-credentials-*
        chmod 600 ~/.config/gh/hosts.*
        chmod 600 ~/.ssh/*
        rm -f "$TMPFILE"
        break
      fi
    fi

    echo "Incorrect passphrase or extraction failed, try again."
    rm -f "$TMPFILE"
  done
fi


# DFPASS='pazwerd'
# tar --disable-copyfile --no-xattrs -cvzf - -s ",^$HOME/,," .git-credentials-* .config/gh/hosts.* .ssh/id_* .ssh/allowed_signers | gpg --batch --yes --passphrase "$DFPASS" --symmetric --cipher-algo AES256 -o ~/Projects/personal/dotfiles/dotfiles/zcnqj7nbbgg4szrm.gpg

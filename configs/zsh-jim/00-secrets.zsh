# Secrets are SOPS-encrypted (age) under configs/secrets/*.enc.env. Decrypt at
# runtime into the interactive shell; no plaintext is written to disk. The age
# private key lives at ~/.config/sops/age/keys.txt (SOPS_AGE_KEY_FILE below).
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

secrets_dir="$HOME/.config/dotfiles/configs/secrets"
if [[ -d "$secrets_dir" ]] && command -v sops >/dev/null 2>&1; then
  if [[ -r "$SOPS_AGE_KEY_FILE" ]]; then
    set -a
    for enc in "$secrets_dir"/*.enc.env; do
      [[ -f "$enc" ]] && source <(sops -d --input-type dotenv --output-type dotenv "$enc")
    done
    set +a
    unset enc
  else
    print -u2 "00-secrets: age key not found at $SOPS_AGE_KEY_FILE; secrets not loaded"
  fi
fi
unset secrets_dir

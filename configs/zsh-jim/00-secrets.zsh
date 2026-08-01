# Secrets are SOPS-encrypted (age) under ~/.secrets/*.enc.env. Decrypt at
# runtime into the interactive shell; no plaintext is written to disk. The age
# private key lives at ~/.config/sops/age/keys.txt (SOPS_AGE_KEY_FILE below).
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

export SECRETS_DIR="$HOME/.secrets"
if [[ -d "$SECRETS_DIR" ]] && command -v sops >/dev/null 2>&1; then
  if [[ -r "$SOPS_AGE_KEY_FILE" ]]; then
    set -a
    for enc in "$SECRETS_DIR"/*.enc.env; do
      [[ -f "$enc" ]] && source <(sops -d --input-type dotenv --output-type dotenv "$enc")
    done
    set +a
    unset enc
  else
    print -u2 "00-secrets: age key not found at $SOPS_AGE_KEY_FILE; secrets not loaded"
  fi
fi

if [[ -d "$HOME/.secrets" ]]; then
  set -a
  for secret_file in "$HOME/.secrets"/*.env; do
    if [[ -f "$secret_file" ]]; then
      source $secret_file
    fi
  done
  set +a
fi

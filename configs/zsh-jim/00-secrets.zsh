if [[ -d "$HOME/.secrets" ]]; then
  for secret_file in "$HOME/.secrets"/*.env; do
    if [[ -f "$secret_file" ]]; then
      source $secret_file
    fi
  done
fi

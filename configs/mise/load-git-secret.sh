#!/usr/bin/env bash
# Sourced by mise (_.source) to load a SOPS-encrypted git profile env into the
# environment. mise cannot decrypt sops dotenv via _.file, so it sources this
# shim, which decrypts the file named by GIT_PROFILE_ENC using the age key.
: "${SOPS_AGE_KEY_FILE:=$HOME/.config/sops/age/keys.txt}"
export SOPS_AGE_KEY_FILE

if [[ -n "${GIT_PROFILE_ENC:-}" && -f "$GIT_PROFILE_ENC" ]]; then
  set -a
  source <(sops -d --input-type dotenv --output-type dotenv "$GIT_PROFILE_ENC")
  set +a
fi

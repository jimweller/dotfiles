# Set DOCKER_HOST for Colima
# Handles both host (macOS) and container (Linux) environments
if [[ -S "$HOME/.colima/docker.sock" ]]; then
    # Socket exists in current home directory (typical for macOS host)
    export DOCKER_HOST=unix://$HOME/.colima/docker.sock
elif [[ -S /var/run/docker.sock ]]; then
    # Standard Docker socket location (Linux)
    export DOCKER_HOST=unix:///var/run/docker.sock
else
    # Fallback: don't set DOCKER_HOST, use default
    unset DOCKER_HOST
fi

# AI-related functions and aliases

# Launch Claude CLI tool in dev container with permissions bypass
claude() {
    # Use devcontainer exec to run assume bedrock then claude inside the container
    ~/dotfiles/scripts/devcontainer.sh exec bash -c "assume bedrock && claude --dangerously-skip-permissions $(printf '%q ' "$@")"
}

# Alias for convenience
alias c='claude'

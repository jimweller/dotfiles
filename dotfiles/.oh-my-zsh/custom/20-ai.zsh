
# AI-related functions and aliases

# Launch Claude CLI tool in dev container with permissions bypass
claude() {
    # Use devcontainer exec to run claude inside the container
    ~/dotfiles/scripts/devcontainer.sh exec claude --dangerously-skip-permissions "$@"
}

# Alias for convenience
alias c='claude'

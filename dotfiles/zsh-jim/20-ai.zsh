
# AI-related functions and aliases

# Launch Claude CLI tool in dev container with permissions bypass
claude_regular() {
    # Use devcontainer exec to run claude inside the container
    # AWS SSO tokens are now mounted from host, so assume may not be needed
    ~/.config/dotfiles/scripts/devcontainer.sh exec claude --dangerously-skip-permissions "$@"
}

# Alias for convenience
alias c='claude_regular'

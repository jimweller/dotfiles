
# AI-related functions and aliases

# Launch Claude CLI tool in dev container with permissions bypass
claude_plain() {
    # Use devcontainer exec to run claude inside the container
    # AWS SSO tokens are now mounted from host, so assume may not be needed
    ~/dotfiles/scripts/devcontainer.sh exec claude --dangerously-skip-permissions "$@"
}

# Alternative function that includes assume (in case tokens aren't available)
claude_assume() {
    # Use devcontainer exec to run assume bedrock then claude inside the container
    ~/dotfiles/scripts/devcontainer.sh exec bash -c "assume bedrock && claude --dangerously-skip-permissions $(printf '%q ' "$@")"
}

# Alias for convenience
alias c='claude_assume'

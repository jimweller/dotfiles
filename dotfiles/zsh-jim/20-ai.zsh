# Raise opencode's hard output-token cap (default 32K) so models can use their full output limit                                                                                       
export OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX=131072

# Fix hardcoded home paths in Claude plugin JSON files (portability across machines)
for f in ~/.claude/plugins/known_marketplaces.json ~/.claude/plugins/installed_plugins.json; do
  real=$(readlink -f "$f" 2>/dev/null || readlink "$f" 2>/dev/null) || continue
  [[ -f "$real" ]] && grep -vq "\"$HOME/" "$real" 2>/dev/null && \
    sed -i.bak -E "s|\"[^\"]*(/\.claude/)|\"${HOME}\1|g" "$real" && rm -f "$real.bak"
done

# AI-related functions and aliases

# Launch Claude CLI tool in dev container with permissions bypass
claude_regular() {
    # Use devcontainer exec to run claude inside the container
    # AWS SSO tokens are now mounted from host, so assume may not be needed
    ~/.config/dotfiles/scripts/devcontainer.sh exec claude --dangerously-skip-permissions "$@"
}

# Alias for convenience
alias c='claude_regular'

# Cloud-specific Claude aliases using --settings flag
alias claws='claude --dangerously-skip-permissions --no-chrome --settings ~/.claude/settings-aws.json'
alias claz='claude --dangerously-skip-permissions --no-chrome --settings ~/.claude/settings-azure.json'
alias claude='claude --dangerously-skip-permissions --no-chrome'

alias opencode='OPENCODE_EXPERIMENTAL_DISABLE_COPY_ON_SELECT=true opencode'

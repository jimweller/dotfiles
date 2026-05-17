# Raise opencode's hard output-token cap (default 32K) so models can use their full output limit                                                                                       
export OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX=131072

# Fix hardcoded home paths in Claude plugin JSON files (portability across machines)
for f in ~/.claude/plugins/known_marketplaces.json ~/.claude/plugins/installed_plugins.json; do
  real=$(readlink -f "$f" 2>/dev/null || readlink "$f" 2>/dev/null) || continue
  [[ -f "$real" ]] && grep -vq "\"$HOME/" "$real" 2>/dev/null && \
    sed -i.bak -E "s|\"[^\"]*(/\.claude/)|\"${HOME}\1|g" "$real" && command rm -f "$real.bak"
done

# AI-related functions and aliases

# Cloud-specific Claude aliases using --settings flag

# overwrite system prompt with humble master persona
# https://thezvi.substack.com/p/opus-47-part-2-capabilities-and-reactions#:~:text=Consider%20changing%20your%20custom%20instructions%2C%20and%20even%20removing%20as%20much%20of%20the%20default%20prompt%20as%20possible
alias claws='claude --dangerously-skip-permissions --no-chrome --settings ~/.claude/settings-aws.json --system-prompt-file ~/.claude/tools/humble-master/daneel-final.md'
alias claz='claude --dangerously-skip-permissions --no-chrome --settings ~/.claude/settings-azure.json --system-prompt-file ~/.claude/tools/humble-master/daneel-final.md'
alias claude='claude --dangerously-skip-permissions --no-chrome --system-prompt-file ~/.claude/tools/humble-master/daneel-final.md'

claude_local() {
  command -v ollama >/dev/null 2>&1 || {
    echo "ollama not found in PATH"
    return 127
  }

  if ! lsof -iTCP:11434 -sTCP:LISTEN -t >/dev/null 2>&1; then
    nohup ollama serve >/dev/null 2>&1 &
    local tries=0
    while ! lsof -iTCP:11434 -sTCP:LISTEN -t >/dev/null 2>&1; do
      sleep 0.5
      tries=$((tries + 1))
      if (( tries > 60 )); then
        echo "ollama failed to start after 30s"
        return 1
      fi
    done
  fi

  ANTHROPIC_BASE_URL=http://localhost:11434 \
  ANTHROPIC_AUTH_TOKEN=ollama \
  ANTHROPIC_MODEL="${CLOCAL_MODEL:-llama3.2:latest}" \
  claude --dangerously-skip-permissions --no-chrome --system-prompt-file ~/.claude/tools/humble-master/daneel-final.md "$@"
}
alias clocal='claude_local'

alias cloai='ANTHROPIC_BASE_URL=http://localhost:4000 claude --dangerously-skip-permissions --no-chrome --system-prompt-file ~/.claude/tools/humble-master/daneel-final.md --settings ~/.claude/settings-litellm-oai.json'
alias clgem='ANTHROPIC_BASE_URL=http://localhost:4000 claude --dangerously-skip-permissions --no-chrome --system-prompt-file ~/.claude/tools/humble-master/daneel-final.md --settings ~/.claude/settings-litellm-gem.json'

# Codex aliases
alias codex='codex --dangerously-bypass-approvals-and-sandbox'

alias opencode='OPENCODE_EXPERIMENTAL_DISABLE_COPY_ON_SELECT=true opencode'

claump() {
  local ids
  ids=$(claude plugin list --json | jq -r '.[] | select(.scope == "user") | .id') || return 1
  for id in ${(f)ids}; do
    echo "Updating $id ..."
    claude plugin update "$id"
  done
}

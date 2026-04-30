# Raise opencode's hard output-token cap (default 32K) so models can use their full output limit                                                                                       
export OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX=131072

# Fix hardcoded home paths in Claude plugin JSON files (portability across machines)
# Debug: set AI_ZSH_DEBUG=1 to trace. Set AI_ZSH_PATH_FIX=0 to skip this block entirely.
if [[ "${AI_ZSH_PATH_FIX:-1}" = 1 ]]; then
  for f in ~/.claude/plugins/known_marketplaces.json ~/.claude/plugins/installed_plugins.json; do
    [[ -n "$AI_ZSH_DEBUG" ]] && print -u2 "[ai.zsh] symlink: $f"
    real=$(readlink -f "$f" 2>/dev/null || readlink "$f" 2>/dev/null) || continue
    [[ -n "$AI_ZSH_DEBUG" ]] && print -u2 "[ai.zsh] real:    $real"
    if [[ ! -f "$real" ]]; then
      [[ -n "$AI_ZSH_DEBUG" ]] && print -u2 "[ai.zsh]   skip: not a regular file"
      continue
    fi
    if ! grep -vq "\"$HOME/" "$real" 2>/dev/null; then
      [[ -n "$AI_ZSH_DEBUG" ]] && print -u2 "[ai.zsh]   skip: already normalized (no foreign HOME paths)"
      continue
    fi
    [[ -n "$AI_ZSH_DEBUG" ]] && print -u2 "[ai.zsh]   sed: normalizing paths"
    if ! sed -i.bak -E "s|\"[^\"]*(/\.claude/)|\"${HOME}\1|g" "$real"; then
      print -u2 "[ai.zsh]   ERROR: sed failed on $real"
      continue
    fi
    [[ -n "$AI_ZSH_DEBUG" ]] && print -u2 "[ai.zsh]   rm -f: $real.bak (rm=$(whence -p rm 2>/dev/null || echo '<none>'))"
    if ! rm -f "$real.bak"; then
      print -u2 "[ai.zsh]   ERROR: rm -f failed on $real.bak (exit $?)"
      ls -la "$real.bak" 2>&1 | sed 's/^/[ai.zsh]     /' >&2
    fi
  done
fi

# AI-related functions and aliases

# Cloud-specific Claude aliases using --settings flag

# overwrite system prompt with humble master persona
# https://thezvi.substack.com/p/opus-47-part-2-capabilities-and-reactions#:~:text=Consider%20changing%20your%20custom%20instructions%2C%20and%20even%20removing%20as%20much%20of%20the%20default%20prompt%20as%20possible
alias claws='claude --dangerously-skip-permissions --no-chrome --settings ~/.claude/settings-aws.json --system-prompt-file ~/.claude/tools/humble-master/daneel-final.md'
alias claz='claude --dangerously-skip-permissions --no-chrome --settings ~/.claude/settings-azure.json --system-prompt-file ~/.claude/tools/humble-master/daneel-final.md'
alias claude='claude --dangerously-skip-permissions --no-chrome --system-prompt-file ~/.claude/tools/humble-master/daneel-final.md'

alias opencode='OPENCODE_EXPERIMENTAL_DISABLE_COPY_ON_SELECT=true opencode'

claump() {
  local ids
  ids=$(claude plugin list --json | jq -r '.[] | select(.scope == "user") | .id') || return 1
  for id in ${(f)ids}; do
    echo "Updating $id ..."
    claude plugin update "$id"
  done
}

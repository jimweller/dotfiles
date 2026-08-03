# Raise opencode's hard output-token cap (default 32K) so models can use their full output limit                                                                                       
export OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX=131072

# Fix hardcoded home paths in Claude plugin JSON files (portability across machines)
for f in ~/.claude/plugins/known_marketplaces.json ~/.claude/plugins/installed_plugins.json; do
  real=$(readlink -f "$f" 2>/dev/null || readlink "$f" 2>/dev/null) || continue
  [[ -f "$real" ]] && grep -vq "\"$HOME/" "$real" 2>/dev/null && \
    sed -i.bak -E "s|\"[^\"]*(/\.claude/)|\"${HOME}\1|g" "$real" && command rm -f "$real.bak"
done

# AI-related functions and aliases

# System prompt composition for Claude Code.
# Repeating --append-system-prompt is last-wins rather than additive, and
# --append-system-prompt cannot be combined with --append-system-prompt-file,
# so both prompts are concatenated here into a single string.

# Humble master persona, read from the humble-master submodule.
_sysprompt_humble() {
  local f="$HOME/.claude/tools/humble-master/daneel-final.md"
  if [[ ! -r $f ]]; then
    print -u2 "sysprompt: cannot read $f"
    return 1
  fi
  cat "$f"
}

# Serena instructions, generated live and cached until serena or its config changes.
# Pass any argument to force regeneration.
_sysprompt_serena() {
  local bin cache cfg tmp
  bin=$(command -v serena) || {
    print -u2 "sysprompt: serena not found in PATH"
    return 1
  }
  cache="${XDG_CACHE_HOME:-$HOME/.cache}/claude-sysprompt/serena.md"
  cfg="$HOME/.serena/serena_config.yml"

  if [[ -n $1 || ! -s $cache || $bin -nt $cache || ( -e $cfg && $cfg -nt $cache ) ]]; then
    mkdir -p "${cache:h}" || return 1
    tmp="${cache}.$$"
    if ! serena print-system-prompt --context claude-code >"$tmp" 2>"${tmp}.err"; then
      print -u2 "sysprompt: serena print-system-prompt failed"
      cat "${tmp}.err" >&2
      command rm -f "$tmp" "${tmp}.err"
      return 1
    fi
    command mv "$tmp" "$cache" && command rm -f "${tmp}.err"
  fi
  cat "$cache"
}

# Builds the combined prompt file and prints its path, for
# --append-system-prompt-file. Passing the content as a file rather than an argv
# string keeps markdown quoting out of the command line entirely.
# Pass any argument to force regeneration of the serena half.
generate_system_prompts() {
  local out tmp
  out="${XDG_CACHE_HOME:-$HOME/.cache}/claude-sysprompt/combined.md"
  mkdir -p "${out:h}" || return 1
  tmp="${out}.$$"

  if ! { _sysprompt_humble && print "" && _sysprompt_serena "$@" } >"$tmp"; then
    command rm -f "$tmp"
    return 1
  fi

  command mv "$tmp" "$out" || return 1
  print -r -- "$out"
}

# Cloud-specific Claude aliases using --settings flag

# append humble master persona plus serena instructions to the built-in prompt
# https://thezvi.substack.com/p/opus-47-part-2-capabilities-and-reactions#:~:text=Consider%20changing%20your%20custom%20instructions%2C%20and%20even%20removing%20as%20much%20of%20the%20default%20prompt%20as%20possible
# Function wrappers rather than aliases: a failed prompt build aborts instead of
# launching without the prompt, and function bodies are not alias-expanded at
# parse time, so other wrappers stay unaffected.
_claude_appended() {
  local sp
  if ! sp=$(generate_system_prompts); then
    print -u2 "claude: aborting, system prompt generation failed"
    return 1
  fi
  command claude --dangerously-skip-permissions --no-chrome \
    --append-system-prompt-file "$sp" "$@"
}

claude() { _claude_appended "$@" }
claws() { _claude_appended --settings ~/.claude/settings-aws.json "$@" }
claz() { _claude_appended --settings ~/.claude/settings-azure.json "$@" }

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

  local model="${CLOCAL_MODEL:-llama3.2:latest}"
  if [[ -n "$1" && "$1" != -* ]]; then
    model="$1"
    shift
  fi

  command claude --dangerously-skip-permissions --no-chrome \
    --settings ~/.claude/settings-ollama.json \
    --model "$model" \
    --system-prompt-file ~/.claude/tools/humble-master/daneel-final.md "$@"
}
alias clocal='claude_local'

alias cloai='ANTHROPIC_BASE_URL=http://localhost:4000 command claude --dangerously-skip-permissions --no-chrome --system-prompt-file ~/.claude/tools/humble-master/daneel-final.md --settings ~/.claude/settings-litellm-oai.json'
alias clgem='ANTHROPIC_BASE_URL=http://localhost:4000 command claude --dangerously-skip-permissions --no-chrome --system-prompt-file ~/.claude/tools/humble-master/daneel-final.md --settings ~/.claude/settings-litellm-gem.json'

# Codex aliases
alias codex='codex --dangerously-bypass-approvals-and-sandbox'

alias opencode='OPENCODE_EXPERIMENTAL_DISABLE_COPY_ON_SELECT=true opencode'

claump() {
  local ids
  ids=$(command claude plugin list --json | jq -r '.[] | select(.scope == "user") | .id') || return 1
  for id in ${(f)ids}; do
    echo "Updating $id ..."
    command claude plugin update "$id"
  done
}

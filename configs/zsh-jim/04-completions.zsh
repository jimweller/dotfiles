# Sources zsh completions for tools that ship no _command file in fpath
# and instead emit completions via a CLI subcommand.
#
# Why this module exists:
#   compinit auto-discovers completions from $fpath. Brew formulae like
#   awscli, kubectl, gh, helm drop _command files in
#   /opt/homebrew/share/zsh/site-functions, which is already in fpath.
#   But several tools ship no static file and require runtime evaluation
#   of their own output (`tool completion zsh`). This module handles those.
#
# Why 04 (between 03-path.zsh and 05-quality-of-life.zsh):
#   PATH must be set first (03-path.zsh) so command -v lookups succeed.
#   Completion sourcing should land before user-facing aliases (05) so
#   that completions exist when the first prompt renders.
#
# Each block is guarded by `command -v` so missing tools cause no errors.
# Some tools (rustup, fzf) emit large completion blocks; sourcing happens
# once per shell.

# Note on timing:
#   This module runs during `antidote load`, before ez-compinit's deferred
#   compinit fires at first prompt. ez-compinit installs a placeholder
#   `compdef` function that queues calls and replays them after real compinit
#   runs. So compdef calls emitted here are queued and applied automatically.

# fzf: emits keybindings (Ctrl-T, Ctrl-R, Alt-C) and completion logic in one
# block. Sourcing has immediate side effects (zle widgets, bindkey) plus
# completion registration.
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# rustup: emits a #compdef block ending with `compdef _rustup rustup`,
# which gets queued by ez-compinit's placeholder for later replay.
if command -v rustup >/dev/null 2>&1; then
  source <(rustup completions zsh)
fi

# opencode: emits BASH-style `complete -F _opencode_yargs_completions opencode`,
# which requires bashcompinit to translate the bash compspec into a compdef
# call. Loading bashcompinit here ensures the `complete` shim is defined when
# the eval runs.
if command -v opencode >/dev/null 2>&1; then
  autoload -Uz bashcompinit && bashcompinit
  source <(opencode completion zsh)
fi

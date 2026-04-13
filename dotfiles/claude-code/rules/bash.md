---
paths:
  - "**/*.sh"
  - "**/*.bats"
---

# Bash Conventions

## Shebang and Flags

Every shell script starts with:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

Never use `#!/bin/bash`. Never omit `set` flags in scripts.

## Environment Sourcing

- Not every working directory is a git repo or has a .envrc. Check before attempting to source.
- NEVER use `source .envrc` with a relative path
- When sourcing: `PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd) && [[ -f "$PROJECT_ROOT/.envrc" ]] && source "$PROJECT_ROOT/.envrc"`

## Script Directory

To find the directory a script is running from:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

## Quoting

- Always double-quote variable expansions: `"$var"`, `"${array[@]}"`
- Use `"$(command)"` not bare `$(command)`

## Style

- Use `[[` instead of `[` for conditionals
- Use `$()` instead of backticks for command substitution
- Prefer `printf` over `echo` for portable output
- Use `local` for function variables

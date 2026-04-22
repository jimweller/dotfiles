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

## Finding Project Root

In a git repo:

```bash
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
```

In a non-git directory (script-relative):

```bash
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

## Environment Sourcing

NEVER use `source .envrc` with a relative path. Resolve `PROJECT_ROOT` using the methods above, then source from it using fully qualified paths:

```bash
source "$PROJECT_ROOT/.envrc"
```

## Quoting

- Always double-quote variable expansions: `"$var"`, `"${array[@]}"`
- Use `"$(command)"` not bare `$(command)`

## Style

- Use `[[` instead of `[` for conditionals
- Use `$()` instead of backticks for command substitution
- Prefer `printf` over `echo` for portable output
- Use `local` for function variables

---
name: markdown-lint
description: Format and lint markdown files using prettier and markdownlint-cli2.
allowed-tools: Bash
---

# Markdown Lint Skill

Format and lint markdown files with auto-fix enabled.

## Usage

To fix all markdown files in the repository, run from the git root:

```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel)
cd "$PROJECT_ROOT"
prettier --write "**/*.md" --ignore-path .gitignore && markdownlint-cli2 --config ~/.config/markdownlint/.markdownlint-cli2.jsonc --fix "**/*.md"
```

To fix a specific file (can run from any directory):

```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel)
prettier --write "path/to/file.md" && markdownlint-cli2 --config ~/.config/markdownlint/.markdownlint-cli2.jsonc --fix "path/to/file.md"
```

## What It Does

1. **Prettier** - Formats markdown (consistent spacing, table alignment, list formatting)
2. **markdownlint-cli2** - Lints and fixes markdown issues (uses config from git root)

## Config Files

- `~/.config/markdownlint/.markdownlint-cli2.jsonc` - global markdownlint config
  - `gitignore: true` - respects .gitignore to skip node_modules, .terraform, etc.
- `.prettierrc` - prettier config if present (in git root)

## Notes

- Prettier runs first because it handles table formatting (fixes MD060 issues)
- Uses global config so linting works consistently across all projects
- Some markdownlint rules (like MD060) are not auto-fixable, but prettier handles them

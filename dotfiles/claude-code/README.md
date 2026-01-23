# Claude Code Configuration

Personal Claude Code configuration for skills, commands, and MCP servers.

## Importing MCP Definitions

```bash
claude mcp add-json -s user context7 "$(cat mcp-context7.json | jq -c)"
claude mcp add-json -s user googleresearcher "$(cat mcp-googleresearcher.json | jq -c)"
claude mcp add-json -s user repomix "$(cat mcp-repomix.json | jq -c)"
```

## Skills

Skills are located in `skills/` and symlinked to `~/.claude/skills/`.

### md-writer

Write well-formed markdown with full conversation context.

- Preloads `md-style` and `md-lint` skills
- Runs prettier and markdownlint after writing

Usage: `/md-writer <file> [additional guidance]`

Examples:

- `/md-writer docs/api.md`
- `/md-writer README.md focus on setup instructions`
- `/md-writer docs/auth.md skip the testing section`

### md-style

Guidelines for writing markdown that passes linting. Covers code block
languages, heading structure, and formatting rules.

### md-lint

Format and lint markdown using prettier and markdownlint-cli2. Uses global
config at `~/.config/markdownlint/.markdownlint-cli2.jsonc`.

## Commands

Commands are located in `commands/` and symlinked to `~/.claude/commands/`.

### md-fix

Fix markdown files using the md-lint skill.

Usage: `/md-fix [file]`

If no file is provided, fixes all markdown files in the repository.

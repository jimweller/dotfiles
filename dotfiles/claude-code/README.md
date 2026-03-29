# Claude Code Configuration

User configuration, skills, commands, and MCP server palettes for Claude Code CLI.

## Usage

Symlink configuration files to `~/.claude/` via dotbot:

```bash
./install.sh
```

## Architecture

| File                             | Description                                                   |
| -------------------------------- | ------------------------------------------------------------- |
| `claude_json`                    | Runtime state, feature flags, cached settings                 |
| `claude_settings_json_azure`     | User preferences, model config, enabled plugins (Azure)       |
| `claude_settings_json_aws`       | User preferences, model config, enabled plugins (AWS)         |
| `claude_settings_json_jim`       | User preferences, model config, enabled plugins (personal)    |
| `_template-claude_json.json`     | Template for claude_json runtime state                        |
| `_template-claude_settings.json` | Template for settings files                                   |
| `_template-mcp.json`             | Template MCP server configuration                             |
| `installed_plugins.json`         | Plugin registry tracking versions and paths                   |
| `CLAUDE.md`                      | Global instructions applied to all sessions                   |
| `statusline-command.sh`          | Custom statusline with git status and context metrics         |
| `ccusage-cache-refresh.sh`       | Refresh ccusage cost cache                                    |

## Skills vs Commands

Both are markdown files with optional YAML frontmatter. Both support `$ARGUMENTS`, positional args, and the same frontmatter fields. The functional difference is auto-activation.

| Feature | Skills | Commands |
| --- | --- | --- |
| Location | `skills/<name>/SKILL.md` | `commands/<name>.md` |
| Invocation | `/name` or auto-activated | `/name` only |
| Auto-activation | Claude loads based on description trigger phrases | Never |
| Directory structure | Supports companion files (scripts/, etc.) | Single file only |
| `${CLAUDE_SKILL_DIR}` | Available | Not available |

Use **skills** for contextual knowledge that should load automatically (markdown rules when editing .md, Jira conventions when discussing tickets). Use **commands** for explicitly-invoked workflows (code reviews, worktree ops, documentation generation).

## Skills

Auto-activated by Claude when context matches trigger phrases.

| Skill                     | Description                                           |
| ------------------------- | ----------------------------------------------------- |
| `ado`                     | Azure DevOps operations via az CLI                    |
| `mcg-confluence-prefs`    | MCG Confluence team defaults and space configuration  |
| `mcg-jira-prefs`          | MCG Jira team defaults, custom fields, creation rules |
| `md-style`                | README writing conventions for concise documentation  |
| `md-syntax`               | Markdown syntax rules and formatting standards        |
| `python`                  | Python development conventions (auto-loads on .py)    |
| `session-migrate`         | Migrate sessions between project folders              |
| `session-resume`          | Search and resume past conversations                  |
| `test-driven-development` | London TDD workflow for features and bugfixes         |
| `transcript-search`       | Search session memory DB for past decisions/context   |

## Commands

Explicitly invoked via `/command-name`.

| Command            | Description                                              |
| ------------------ | -------------------------------------------------------- |
| `code-reviews`     | Parallel code reviews via 3 models through opencode      |
| `commit`           | Atomic conventional commit with AI context tracking      |
| `handoff`          | Session handoff document for next agent                  |
| `md-lint`          | Format markdown with prettier and markdownlint-cli2      |
| `ralph-builder`    | Build Ralph Wiggum loop files for autonomous execution   |
| `ralph-reviewer`   | Review Ralph loop files via 3 models through opencode    |
| `transcript-save`  | Manually ingest current session transcript to memory DB  |
| `update-all-docs`  | Update README, CLAUDE.md, and .llmdocs/ in parallel      |
| `update-llm-docs`  | Maintain CLAUDE.md and .llmdocs/ directory               |
| `update-readme`    | Generate README from folder contents and conversation    |
| `worktree`         | Git worktree create, merge, rebase, remove               |

## STARTER_CHARACTER System

Every response begins with emoji indicators showing active skills/commands:

- Default: `✳️`
- With Jira: `✳️ 🎟️`
- Multiple active: `✳️ 🎟️ 📝`

## Statusline

Custom statusline showing directory, git status, model, context usage, and cost. Context bar uses colorblind-safe colors with severity glyphs.

| Context Level | Color | Icon |
| --- | --- | --- |
| < 40% | steel blue | robot |
| >= 40% | yellow | head-question |
| >= 75% | pink | skull |
| >= 90% | dark red | skull |

| Git Indicator | Meaning                 |
| ------------- | ----------------------- |
| `⇣N`          | Commits behind remote   |
| `⇡N`          | Commits ahead of remote |
| `*N`          | Stash count             |
| `~N`          | Merge conflicts         |
| `+N`          | Staged changes          |
| `!N`          | Unstaged changes        |
| `?N`          | Untracked files         |

## File Structure

```text
claude-code/
├── claude_json                        # Runtime state
├── claude_settings_json_azure         # Settings for Azure provider
├── claude_settings_json_aws           # Settings for AWS provider
├── claude_settings_json_jim           # Settings for personal use
├── _template-claude_json.json         # Template for runtime state
├── _template-claude_settings.json     # Template for settings files
├── _template-mcp.json                 # Template for MCP config
├── installed_plugins.json             # Plugin registry
├── CLAUDE.md                          # Global instructions
├── README.md
├── statusline-command.sh              # Custom statusline script
├── ccusage-cache-refresh.sh           # Refresh cost cache
├── commands/
│   ├── code-reviews.md
│   ├── commit.md
│   ├── handoff.md
│   ├── md-lint.md
│   ├── ralph-builder.md
│   ├── ralph-reviewer.md
│   ├── transcript-save.md
│   ├── update-all-docs.md
│   ├── update-llm-docs.md
│   ├── update-readme.md
│   └── worktree.md
├── hooks/
│   └── ingest-transcript.sh           # PostCompact/SessionEnd transcript hook
├── skills/
│   ├── ado/
│   ├── mcg-confluence-prefs/
│   ├── mcg-jira-prefs/
│   ├── md-style/
│   ├── md-syntax/
│   ├── python/
│   ├── session-migrate/
│   ├── session-resume/
│   ├── test-driven-development/
│   └── transcript-search/
└── tools/
    └── total-recall/                  # SQLite-backed session memory (submodule)
```

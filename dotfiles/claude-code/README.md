# Claude Code Configuration

User configuration, skills, and MCP server palettes for Claude Code CLI.

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

## Skills

All automation is consolidated into skills. Commands were migrated to skills after the v2.1.3 merge unified the two systems. See `skills/README.md` for the full inventory, frontmatter reference, and invocation modes.

| Mode | Frontmatter | Skills |
|---|---|---|
| Human + Model | default | commit, md-lint, update-llm-docs, update-readme, session-migrate, session-resume, test-driven-development, transcript-search, sage |
| Human-only | `disable-model-invocation: true` | familiarize, worktree, handoff, code-reviews, ralph-builder, ralph-reviewer, update-all-docs |
| Model-only | `user-invocable: false` | ado, mcg-confluence-prefs, mcg-jira-prefs, md-style, md-syntax, python |

## STARTER_CHARACTER System

Every response begins with emoji indicators showing active skills:

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
├── hooks/
│   └── ingest-transcript.sh           # PostCompact/SessionEnd transcript hook
├── skills/
│   ├── README.md                      # Skill inventory and frontmatter reference
│   ├── ado/
│   ├── code-reviews/
│   ├── commit/
│   ├── familiarize/
│   ├── handoff/
│   ├── mcg-confluence-prefs/
│   ├── mcg-jira-prefs/
│   ├── md-lint/
│   ├── md-style/
│   ├── md-syntax/
│   ├── python/
│   ├── ralph-builder/
│   ├── ralph-reviewer/
│   ├── sage/
│   ├── session-migrate/
│   ├── session-resume/
│   ├── test-driven-development/
│   ├── transcript-search/
│   ├── update-all-docs/
│   ├── update-llm-docs/
│   ├── update-readme/
│   └── worktree/
└── tools/
    └── total-recall/                  # SQLite-backed session memory (submodule)
```

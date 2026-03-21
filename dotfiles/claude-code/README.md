# Claude Code Configuration

User configuration, skills, commands, and MCP server palettes for Claude Code CLI.

## Usage

Symlink configuration files to `~/.claude/` via dotbot:

```bash
./install.sh
```

## Architecture

| File                            | Description                                                   |
| ------------------------------- | ------------------------------------------------------------- |
| `claude_json`                   | Runtime state, feature flags, cached settings                 |
| `claude_settings_json_azure`    | User preferences, model config, enabled plugins (Azure)       |
| `claude_settings_json_aws`      | User preferences, model config, enabled plugins (AWS)         |
| `claude-baseline-template.json` | Template MCP server configuration                             |
| `mcp-palette.json`              | Extended MCP server palette (Azure DevOps, Atlassian, GitHub) |
| `installed_plugins.json`        | Plugin registry tracking versions and paths                   |
| `CLAUDE.md`                     | Global instructions applied to all sessions                   |
| `statusline-command.sh`         | Custom statusline with git status and context metrics         |

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

| Skill                    | Description                                          |
| ------------------------ | ---------------------------------------------------- |
| `ado`                    | Azure DevOps operations via az CLI                   |
| `jira`                   | Jira issue operations via MCP ATL tools              |
| `md-style`               | README writing conventions for concise documentation |
| `md-syntax`              | Markdown syntax rules and formatting standards       |
| `test-driven-development`| London TDD workflow for features and bugfixes        |
| `session-migrate`        | Migrate sessions between project folders             |
| `session-resume`         | Search and resume past conversations                 |

## Commands

Explicitly invoked via `/command-name`.

| Command            | Description                                               |
| ------------------ | --------------------------------------------------------- |
| `code-reviews`     | Parallel code reviews via 3 models through opencode       |
| `commit`           | Atomic conventional commit with AI context tracking       |
| `handoff`          | Session handoff document for next agent                   |
| `md-lint`          | Format markdown with prettier and markdownlint-cli2       |
| `ralph-builder`    | Build Ralph Wiggum loop files for autonomous execution    |
| `ralph-reviewer`   | Review Ralph loop files via 3 models through opencode     |
| `update-llm-docs`  | Maintain CLAUDE.md and .llmdocs/ directory                |
| `update-readme`    | Generate documentation from folder contents               |
| `worktree`         | Git worktree create, merge, rebase, remove                |

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
├── claude_json
├── claude_settings_json_azure
├── claude_settings_json_aws
├── claude-baseline-template.json
├── mcp-palette.json
├── installed_plugins.json
├── CLAUDE.md
├── README.md
├── statusline-command.sh
├── commands/
│   ├── code-reviews.md
│   ├── commit.md
│   ├── handoff.md
│   ├── md-lint.md
│   ├── ralph-builder.md
│   ├── ralph-reviewer.md
│   ├── update-llm-docs.md
│   ├── update-readme.md
│   └── worktree.md
└── skills/
    ├── ado/
    ├── jira/
    ├── md-style/
    ├── md-syntax/
    ├── session-migrate/
    ├── session-resume/
    └── test-driven-development/
```

# Claude Code Skills

All Claude Code automation lives here as skills. Commands were migrated to skills after the v2.1.3 merge unified the two systems (GitHub issue #13115, #14945).

## Why Skills Only

Before v2.1.3, commands and skills were separate: commands were user-invoked `.md` files, skills were auto-triggered directories with `SKILL.md`. The merge made skills directly invocable via the `/` menu, eliminating the need for a parallel commands system. Frontmatter booleans control all invocation behavior.

## Frontmatter Reference

| Field | Default | Effect |
|---|---|---|
| `name` | required | Skill identifier, appears as `/name` in slash menu |
| `description` | required | Trigger condition for auto-discovery + menu description |
| `disable-model-invocation` | `false` | When `true`, only humans can invoke via `/name`. Model cannot trigger autonomously. |
| `user-invocable` | `true` | When `false`, skill is hidden from `/` menu. Model-only. |
| `argument-hint` | none | Placeholder text shown in autocomplete |
| `context` | none | `fork` runs in a subprocess to protect main context |

## Invocation Modes

| Mode | Frontmatter | Use Case |
|---|---|---|
| Both (default) | no flags | Model auto-triggers on context match, user can invoke via `/name` |
| Human-only | `disable-model-invocation: true` | Expensive or destructive operations the user must initiate |
| Model-only | `user-invocable: false` | Contextual rules the model loads automatically |

## Skill Inventory

### Human + Model Invocable

| Skill | Description |
|---|---|
| `commit` | Atomic conventional commit with AI context tracking |
| `md-lint` | Format and lint markdown with prettier + markdownlint-cli2 |
| `update-llm-docs` | Update CLAUDE.md and .llmdocs/ after significant work |
| `update-readme` | Generate README from folder contents and conversation |
| `session-migrate` | Migrate sessions between project folders |
| `session-resume` | Search and resume past conversations |
| `test-driven-development` | London TDD workflow for features and bugfixes |
| `transcript-search` | Search session memory DB for past decisions/context |
| `sage` | Research via c7 (library docs) and g (web search) MCP servers |

### Human-Only (`disable-model-invocation: true`)

| Skill | Description |
|---|---|
| `familiarize` | Orient in a new repo by reading docs, config, and code structure |
| `worktree` | Git worktree create, merge, rebase, remove |
| `handoff` | Write session handoff document for next agent |
| `code-reviews` | Parallel code reviews via 3 models through opencode |
| `ralph-builder` | Build Ralph Wiggum loop files for autonomous execution |
| `ralph-reviewer` | Review Ralph loop files via 3 models through opencode |
| `update-all-docs` | Run update-llm-docs and update-readme in parallel |

### Model-Only (`user-invocable: false`)

| Skill | Description |
|---|---|
| `ado` | Azure DevOps operations via az CLI |
| `mcg-confluence-prefs` | MCG Confluence team defaults and space config |
| `mcg-jira-prefs` | MCG Jira team defaults, custom fields, creation rules |
| `md-style` | README writing conventions |
| `md-syntax` | Markdown syntax and formatting rules |
| `python` | Python development conventions (uv, src layout, pytest) |

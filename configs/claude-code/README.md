# Claude Code Configuration

User configuration, skills, hooks, rules, and tools for [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code).

## Usage

Symlinked to `~/.claude/` via [dotbot](https://github.com/anishathalye/dotbot):

```bash
./install
```

## Architecture

| File                             | Description                                                                    |
| -------------------------------- | ------------------------------------------------------------------------------ |
| `claude_json`                    | Runtime state, feature flags, cached settings                                  |
| `claude_settings_json_azure`     | Active settings file (symlinked to `~/.claude/settings.json`)                  |
| `claude_settings_json_aws`       | Settings variant for AWS Bedrock (`CLAUDE_CODE_USE_BEDROCK=1`)                 |
| `claude_settings_json_jim`       | Settings variant for personal/direct API                                       |
| `_template-claude_json.json`     | Template for runtime state                                                     |
| `_template-claude_settings.json` | Template for settings files                                                    |
| `_template-mcp.json`             | Template MCP server configuration                                              |
| `installed_plugins.json`         | Plugin registry tracking versions and paths                                    |
| `known_marketplaces.json`        | Plugin marketplace registry                                                    |
| `CLAUDE.md`                      | Global instructions applied to all sessions                                    |
| `statusline-command.sh`          | Custom statusline with git, model, context, and cost                           |
| `ccusage-cache-refresh.sh`       | Refresh [ccusage](https://github.com/ryoppippi/ccusage) cost cache via launchd |

Settings are maintained in `claude_settings_json_azure` first, then synced to `_aws` and `_jim`. The only difference is the provider env: azure uses `CLAUDE_CODE_USE_FOUNDRY=1`, aws uses `CLAUDE_CODE_USE_BEDROCK=1`.

## Rules

Path-scoped [rules](https://docs.anthropic.com/en/docs/claude-code/memory#organize-rules-with-clauderules) loaded automatically when Claude reads matching files. Symlinked to `~/.claude/rules/` via dotbot glob.

| Rule            | Scope                          | Description                                                                                   |
| --------------- | ------------------------------ | --------------------------------------------------------------------------------------------- |
| `bash.md`       | `**/*.sh`, `**/*.bats`         | Shebang, set flags, project root, .envrc sourcing, quoting                                    |
| `lsp-serena.md` | all sessions                   | Prefer [Serena](https://github.com/oraios/serena) MCP over Grep/Glob/Read for code navigation |
| `md-style.md`   | `**/README.md`                 | README writing style and structure                                                            |
| `md-syntax.md`  | `**/*.md`                      | Markdown formatting conventions                                                               |
| `python.md`     | `**/*.py`, `**/pyproject.toml` | uv, src layout, pytest, ruff conventions                                                      |

## Hooks

Event-driven scripts fired by Claude Code at specific lifecycle points. Symlinked to `~/.claude/hooks/` via dotbot glob.

The [rtk-rewrite](https://github.com/rtk-ai/rtk) and stop-phrase-guard hooks address [Claude Code degradation](https://github.com/anthropics/claude-code/issues/42796) where the model loses instruction adherence mid-session. See the [degradation workaround thread](https://www.reddit.com/r/ClaudeCode/comments/1sglv19/claudecode_degradation_workaround_get_back_on/) for background.

| Hook                         | Event                   | Source                                                                              |
| ---------------------------- | ----------------------- | ----------------------------------------------------------------------------------- |
| `ingest-transcript.sh`       | PreCompact, SessionEnd  | Local                                                                               |
| `rtk-rewrite.sh`             | PreToolUse (Bash)       | [code-factory](https://github.com/rtfpessoa/code-factory)                           |
| `command-safety-scanner.sh`  | PreToolUse (Bash)       | [code-factory](https://github.com/rtfpessoa/code-factory)                           |
| `stop-phrase-guard.sh`       | Stop                    | [code-factory](https://github.com/rtfpessoa/code-factory)                           |
| `lsp-first-guard.js`         | PreToolUse (Grep)       | [lsp-enforcement-kit](https://github.com/nesaminua/claude-code-lsp-enforcement-kit) |
| `lsp-first-glob-guard.js`    | PreToolUse (Glob)       | lsp-enforcement-kit                                                                 |
| `lsp-first-read-guard.js`    | PreToolUse (Read)       | lsp-enforcement-kit                                                                 |
| `bash-grep-block.js`         | PreToolUse (Bash)       | lsp-enforcement-kit                                                                 |
| `lsp-pre-delegation.js`      | PreToolUse (Agent)      | lsp-enforcement-kit                                                                 |
| `lsp-usage-tracker.js`       | PostToolUse (LSP calls) | lsp-enforcement-kit                                                                 |
| `lsp-session-reset.js`       | SessionStart            | lsp-enforcement-kit                                                                 |

## Skills

Automation consolidated into [skills](https://docs.anthropic.com/en/docs/claude-code/skills). See `skills/README.md` for the full inventory.

| Mode          | Frontmatter                      | Skills                                                                                                                             |
| ------------- | -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Human + Model | default                          | commit, md-lint, llmdocs, readme, session-migrate, session-resume, test-driven-development, transcript-search, sage |
| Human-only    | `disable-model-invocation: true` | familiarize, worktree, handoff, code-reviews, ralph-builder, ralph-reviewer, docs                                       |
| Model-only    | `user-invocable: false`          | ado, mcg-confluence-prefs, mcg-jira-prefs                                                                                          |

## Tools

Git submodules providing additional capabilities.

| Tool                                                                                | Description                                                       |
| ----------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| [lsp-enforcement-kit](https://github.com/nesaminua/claude-code-lsp-enforcement-kit) | Hooks enforcing LSP-first navigation over Grep/Glob/Read          |
| [total-recall](https://github.com/anthropics/claude-code)                           | SQLite-backed session memory with embeddings and semantic linking |

## Statusline

Custom statusline showing directory, git status, model, context usage, and cost.

| Context Level | Color      | Icon          |
| ------------- | ---------- | ------------- |
| < 40%         | steel blue | robot         |
| >= 40%        | yellow     | head-question |
| >= 75%        | pink       | skull         |
| >= 90%        | dark red   | skull         |

## File Structure

```text
claude-code/
├── claude_json
├── claude_settings_json_azure
├── claude_settings_json_aws
├── claude_settings_json_jim
├── CLAUDE.md
├── statusline-command.sh
├── ccusage-cache-refresh.sh
├── hooks/
│   ├── command-safety-scanner.sh
│   ├── ingest-transcript.sh
│   ├── rtk-rewrite.sh
│   └── stop-phrase-guard.sh
├── rules/
│   ├── bash.md
│   ├── lsp-serena.md
│   ├── md-style.md
│   ├── md-syntax.md
│   └── python.md
├── skills/
│   ├── ado/
│   ├── code-reviews/
│   ├── commit/
│   ├── familiarize/
│   ├── handoff/
│   ├── mcg-confluence-prefs/
│   ├── mcg-jira-prefs/
│   ├── md-lint/
│   ├── ralph-builder/
│   ├── ralph-reviewer/
│   ├── sage/
│   ├── session-migrate/
│   ├── session-resume/
│   ├── test-driven-development/
│   ├── transcript-search/
│   ├── docs/
│   ├── llmdocs/
│   ├── readme/
│   └── worktree/
└── tools/
    ├── lsp-enforcement-kit/
    └── total-recall/
```

# Claude Code Configuration

User configuration, skills, and MCP server palettes for Claude Code CLI.

## Usage

Symlink configuration files to `~/.claude/`:

```bash
# Via dotfiles installer
./install.sh

# Manual
ln -s dotfiles/claude-code/claude_json ~/.claude/claude.json
ln -s dotfiles/claude-code/claude_settings_json ~/.claude/claude_settings.json
```

## Architecture

| File                            | Description                                                   |
| ------------------------------- | ------------------------------------------------------------- |
| `claude_json`                   | Runtime state, feature flags, cached settings                 |
| `claude_settings_json`          | User preferences, model config, enabled plugins               |
| `claude-baseline-template.json` | Template MCP server configuration                             |
| `mcp-palette.json`              | Extended MCP server palette (Azure DevOps, Atlassian, GitHub) |
| `installed_plugins.json`        | Plugin registry tracking versions and paths                   |
| `CLAUDE.md`                     | Global instructions applied to all sessions                   |
| `statusline-command.sh`         | Custom statusline with git status and context metrics         |

## Skills

Skills extend Claude Code with specialized behaviors. Invoke with `/skill-name`.

| Skill                  | Emoji | Description                                          |
| ---------------------- | ----- | ---------------------------------------------------- |
| `jira`                 | 🎟️   | Jira issue operations via MCP ATL tools              |
| `md-lint`              | 🔏    | Format markdown with prettier and markdownlint-cli2  |
| `md-style`             | 📝    | README writing conventions for concise documentation |
| `md-syntax`            | 🔏    | Markdown syntax rules and formatting standards       |
| `readme`               | 📓    | Generate documentation from folder contents          |
| `update-llm-docs`      | -     | Maintain CLAUDE.md and docs/ directory               |
| `claude-search-resume` | -     | Search and resume past conversations                 |

### Skill Structure

```text
skills/
└── skill-name/
    ├── SKILL.md        # Manifest with name, description, STARTER_CHARACTER
    └── scripts/        # Optional executables
```

### STARTER_CHARACTER System

Every response begins with emoji indicators showing active skills:

- Default: `✳️`
- With Jira: `✳️ 🎟️`
- Multiple skills: `✳️ 🎟️ 📝`

## Statusline

Custom statusline showing directory, git status, model, context remaining, and cost.

```text
~/projects/app on ⎇ main ⇣2 ⇡1 +3 !1 ?2 using opus [75% left] $0.42
```

| Indicator | Meaning                 |
| --------- | ----------------------- |
| `⇣N`      | Commits behind remote   |
| `⇡N`      | Commits ahead of remote |
| `*N`      | Stash count             |
| `~N`      | Merge conflicts         |
| `+N`      | Staged changes          |
| `!N`      | Unstaged changes        |
| `?N`      | Untracked files         |

Context percentage color-coded: green (>50%), yellow (20-50%), red (<20%).

## Configuration

Enable statusline in `claude_settings_json`:

```json
{
  "statusline": {
    "enabled": true,
    "command": "~/.claude/statusline-command.sh"
  }
}
```

## File Structure

```text
claude-code/
├── claude_json
├── claude_settings_json
├── claude-baseline-template.json
├── mcp-palette.json
├── installed_plugins.json
├── CLAUDE.md
├── statusline-command.sh
└── skills/
    ├── jira/
    ├── md-lint/
    ├── md-style/
    ├── md-syntax/
    ├── readme/
    ├── update-llm-docs/
    └── claude-search-resume/
```

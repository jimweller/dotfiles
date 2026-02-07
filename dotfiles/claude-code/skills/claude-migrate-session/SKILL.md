---
name: claude-migrate-session
description: Migrate a Claude Code session from another project folder to the current directory so claude --continue picks it up.
argument-hint: "[keyword]"
---

STARTER_CHARACTER = 🚚

# Claude Migrate Session

Migrate a conversation from another project to the current working directory.

## When to use

- User wants to continue a session that was started in a different project folder
- User wants to move a conversation to their current project

## Workflow

1. **Search** — Run the search script with `--global` (always global since migration implies cross-folder). Pass the user's keyword argument if provided.

```bash
~/.claude/skills/claude-search-resume/scripts/claude-search-resume --global
~/.claude/skills/claude-search-resume/scripts/claude-search-resume "keyword" --global
```

2. **Display & Ask** — Show the search results to the user. Ask which session they want to migrate (by number or session ID).

3. **Guard** — Before migrating, check that the session's project path (shown in the search output) is NOT already the current working directory. If it is, tell the user the session is already local and there's nothing to migrate.

4. **Migrate** — Run the migrate script with the chosen session ID:

```bash
~/.claude/skills/claude-migrate-session/scripts/claude-migrate-session --session-id <uuid>
```

5. **Instruct** — Tell the user to quit this session and run:

```bash
claude --continue
```

## Notes

- The migrate script copies (not moves) session files — the original session stays intact in the source project
- No JSON rewriting is needed — just copying the files works
- The script handles both the `.jsonl` file and any subagents directory

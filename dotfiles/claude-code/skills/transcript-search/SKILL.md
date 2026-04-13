---
name: transcript-search
description: Search saved session transcripts for past decisions, actions, errors, and context that has left the current conversation window.
---

<!-- markdownlint-disable-file MD041 -->

STARTER_CHARACTER = 🗃️

# Transcript Search

Search the global session memory database for past conversations using hybrid
FTS5 + vector retrieval.

## When to use

- User asks about something from a previous session or earlier in a long session
- User references a past decision, error, action, or discussion no longer in context
- User asks "what did we do about X", "when did we fix Y", "what error did we get"

## Database location

`~/.claude/session_memory.db` (global, all projects)

## Retrieval tool

```bash
TR=~/.config/dotfiles/dotfiles/claude-code/tools/total-recall
$TR/.venv/bin/python $TR/retrieve.py "QUERY" --db ~/.claude/session_memory.db
```

Default output is `--format context` which produces XML-tagged conversation
excerpts ready to read directly.

## Common flags

| Flag                     | Purpose                                              |
| ------------------------ | ---------------------------------------------------- |
| `--project NAME`         | Restrict to a specific project                       |
| `--top-k N`              | Number of seed matches before expansion (default: 5) |
| `--window N`             | Context window +/- N around each match (default: 2)  |
| `--budget N`             | Max chunks in final output (default: 20)             |
| `--tokens N`             | Max tokens in final output (default: 6000)           |
| `--session ID`           | Restrict to a specific session_id                    |
| `--no-tools`             | Exclude tool_use/tool_result chunks                  |
| `--no-vectors`           | FTS5 keyword search only (skip embeddings)           |
| `--format json`          | JSON array output for programmatic use               |
| `--roles user,assistant` | Filter by role                                       |

## Search procedure

1. Run retrieve.py with the user's query
2. Read the returned context block
3. If results are too broad, narrow with `--project` or `--session`
4. If results are too sparse, increase `--top-k` or `--budget`
5. For keyword-exact searches, use `--no-vectors` to restrict to FTS5

## Tips

- The retrieval pipeline uses RRF fusion of keyword + vector search, window
  expansion, ancestor backtracking, and cross-session semantic links
- Use `--no-tools` when searching for decisions or discussion (skips noisy
  tool output)
- Use `--format json` when you need to process results programmatically

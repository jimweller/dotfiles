---
name: beads
description: bd (beads) issue tracker workflow and command reference. Apply when bd commands appear, when interacting with the beads CLI, when working with a .beads/ database, or when any task tracking via bd or beads is needed.
---

<!-- markdownlint-disable-file MD041 -->

STARTER_CHARACTER = 📿

# Beads

bd (beads) is a graph-based issue tracker with first-class dependency support. It is the canonical task tracker for projects that have a `.beads/` directory. Do not substitute `TodoWrite`, `TaskCreate`, or markdown TODO lists when bd is in use.

## Core commands

```bash
bd ready                  # find ready work (open, no active blockers)
bd show <id>              # view issue details
bd create "<title>"       # create a new issue (full flag surface)
bd q "<title>" -t <type>  # quick capture, outputs only the new issue ID
bd update <id> -d "<desc>"  # set description
bd link <a> <b>           # add dependency edge: b blocks a
bd close <id>             # complete work
bd dep cycles             # detect cycles
bd dolt push              # push beads data to remote
```

## ID capture in scripts

`bd q` is the simplest path when only the ID is needed. It accepts `-t`, `-p`, `-l`, but not `--parent` or `-d`.

When extra flags are needed (parent linkage, description, multiple labels) and the ID still must be captured cleanly, use `bd create` with `-q --json`:

```bash
id=$(bd create "title" -t task -p 1 --parent "${epic}" -l "ralph:${slug}" -q --json | jq -r .id)
```

`-q` suppresses the test-data warning that otherwise prefixes JSON output, and the JSON is stable to parse.

## Filters and queries

```bash
bd ready --parent <epic-id>            # ready work scoped to an epic's children
bd ready --label <label>               # ready work with a label
bd list --parent <epic-id>             # full descendants tree
bd list --label <label>                # all issues with a given label
bd list --label <label> --json         # machine-readable; pipe to jq
bd list --status open,in_progress      # status filter (comma-separated)
bd list -t epic                        # type filter
```

`bd ready`, `bd list`, `bd show` are read-only and never write to the database.

## Hierarchy and partition

`bd` supports first-class parent-child via `--parent <id>`. A child is auto-numbered as `<parent>.<n>` (e.g., epic `bd-abc` has children `bd-abc.1`, `bd-abc.2`). Common pattern: one epic per logical run, all tasks parented to it; filter via `--parent <epic>` to scope work.

bd does not auto-close epics. Closing all children leaves the epic open until `bd close <epic>` runs explicitly. Auto-close exists for molecules, not epics.

## Worktrees

`bd` discovers `.beads/` via `git rev-parse --git-common-dir`, so all worktrees of the same repo share one database by default. Embedded Dolt serializes concurrent writes via `.exclusive-lock`; multi-writer concurrency requires server mode (`bd dolt start`).

`.beads/redirect` is internal sync-branch plumbing; do not author it manually. For per-worktree DB isolation, the documented mechanism is `BEADS_DIR=<path>` env var (see bd's WORKTREES.md).

## Discovery commands

```bash
bd prime                  # full command reference (run inside any beads project)
bd help <subcommand>      # per-command details
bd worktree info          # show worktree's beads config
bd doctor                 # health checks (server mode only)
```

## Common pitfalls

- `bd init` (default) writes `AGENTS.md`, modifies `CLAUDE.md`, and creates `.claude/settings.json`. Pass `--skip-agents` to suppress all three when the project already provides agent guidance via other means.
- `bd init` refuses to re-initialize a worktree that resolves to an existing `.beads/` via common-dir discovery. To create a worktree-local DB, use `BEADS_DIR=<path>` instead of `--reinit-local`.
- Embedded Dolt is single-writer. Two simultaneous `bd update`/`bd close` calls block on `.exclusive-lock`; they do not corrupt.
- Children created without `--parent` are orphans. Defense-in-depth: also apply a uniform run-identity label so a parity check (`bd list --parent <epic>` vs `bd list --label <label>`) detects orphans.

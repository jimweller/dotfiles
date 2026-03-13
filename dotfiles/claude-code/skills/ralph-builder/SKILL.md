---
name: ralph-builder
description: Build or update Ralph Wiggum loop files in .llmdocs for autonomous task execution.
user-invocable: true
argument-hint: "<goal or filename>"
---

STARTER_CHARACTER = 🔁

# Ralph Builder

Build or update the three Ralph Wiggum loop files in `.llmdocs/` so a ralph loop can execute autonomously against the current repo.

Arguments: $ARGUMENTS

The argument is a goal description. It may reference a file containing a PRD, plan, or task list.

## Output Files

All files go in `<PROJECT_ROOT>/.llmdocs/`. Create the directory if it does not exist.

| File                     | Purpose                                              |
| ------------------------ | ---------------------------------------------------- |
| `_ralph-prompt.md`       | The `/ralph-loop:ralph-loop` invocation command      |
| `_ralph-tasks.md`        | Checklist of discrete tasks                          |
| `_ralph-instructions.md` | Detailed instructions for accomplishing the goal     |

## Procedure

### Step 1: Gather Context

Read these files to understand the repo:

1. `CLAUDE.md` (project root)
2. `README.md` (project root)
3. All non-underscore `.md` files in `.llmdocs/` (architecture, api, data-model, deployment, ops, etc.)
4. Any file referenced in $ARGUMENTS

If `.llmdocs/` does not exist, create it.

If `_ralph-tasks.md`, `_ralph-instructions.md`, or `_ralph-prompt.md` already exist, read them before overwriting.

### Step 2: Build _ralph-tasks.md

Create a checklist of discrete, sequentially-ordered tasks derived from the goal and repo context. The 
task lists describes what steps to take, not how to do them. The HOW should come from other referenced documents.

Format:

```markdown
- [ ] First task
- [ ] Second task
- [ ] Third task
```

Rules:
- Each task is a single, independently-completable unit of work
- Tasks are ordered by dependency (earlier tasks unblock later ones)
- Use imperative voice
- Be specific enough that Claude can execute the task without ambiguity
- Reference specific files, modules, or components when relevant
- Do not include meta-tasks like "read the codebase" or "understand the architecture"
- ONLY put checkbox items in the task file. No other headings or prose.
- ONLY put task descriptions. Say *what* to do, not *how* to do it.

### Step 3: Build _ralph-instructions.md

Write instructions that tell Claude how to accomplish the overall goal within this specific repo.

Format:

```markdown
# Ralph Instructions

## Goal

<one paragraph summary of the objective>

## Approach

<strategy and sequencing>

## Conventions

<repo-specific patterns, tools, test commands, build commands, commit style>

## Per-Task Workflow

For each task, follow London TDD (mock-first):
1. Write a failing test that defines the expected behavior
2. Write the minimum code to make the test pass
3. Refactor if needed while keeping tests green

Do NOT commit. The user will commit after reviewing changes.
Mark the task [x] in _ralph-tasks.md when complete.

## References

<list of key files and docs to consult>
```

Rules:
- Ground instructions in the actual repo structure and tooling
- Include build, test, and lint commands if known
- Explicitly state that ralph must NOT commit
- Reference the project's CLAUDE.md rules
- Define what "done" means for a task (tests pass, linter clean, etc.)

### Step 4: Build _ralph-prompt.md

Write exactly this static invocation. Only adjust `--max-iterations`.

```markdown
/ralph-loop:ralph-loop "Read @.llmdocs/_ralph-instructions.md and follow its instructions. Work through @.llmdocs/_ralph-tasks.md one task at a time. Mark items [x] when complete. Output <promise>ALLDONE</promise> when all tasks are complete." --max-iterations 100 --completion-promise ALLDONE
```

Rules:
- The prompt text is fixed. Do not add `@` file references beyond `_ralph-instructions.md` and `_ralph-tasks.md`. All other file references belong in `_ralph-instructions.md`.
- Set `--max-iterations` proportional to task count (roughly 2-3x the number of tasks, minimum 20, maximum 100)
- Always use `--completion-promise ALLDONE`

### Step 5: Report

List the three files created/updated and summarize the task count.

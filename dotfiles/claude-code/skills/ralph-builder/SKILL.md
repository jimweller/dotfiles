---
name: ralph-builder
description: Build or update Ralph Wiggum loop files in .claude/docs for autonomous task execution.
user-invocable: true
argument-hint: "<goal or filename>"
---

STARTER_CHARACTER = 🔁

# Ralph Builder

Build or update the three Ralph Wiggum loop files in `.claude/docs/` so a ralph loop can execute autonomously against the current repo.

Arguments: $ARGUMENTS

The argument is a goal description. It may reference a file containing a PRD, plan, or task list.

## Output Files

All files go in `<PROJECT_ROOT>/.claude/docs/`. Create the directory if it does not exist.

| File                     | Purpose                                              |
| ------------------------ | ---------------------------------------------------- |
| `_ralph-prompt.md`       | The `/ralph-loop:ralph-loop` invocation command      |
| `_ralph-tasks.md`        | Checklist of discrete tasks                          |
| `_ralph-instructions.md` | Detailed instructions for accomplishing the goal     |

## Procedure

### Step 1: Gather Context

Read these files to understand the repo:

1. `README.md` (project root)
2. All non-underscore `.md` files in `.claude/docs/` (architecture, api, data-model, deployment, testing, ops, etc.)
3. Any file referenced in $ARGUMENTS

If `.claude/docs/` does not exist, create it.

If `_ralph-tasks.md`, `_ralph-instructions.md`, or `_ralph-prompt.md` already exist, read them before overwriting.

### Step 2: Build \_ralph-tasks.md

Create a checklist of discrete, sequentially-ordered tasks derived from the goal and repo context. The task list describes what steps to take, not how to do them. The HOW should come from other referenced documents.

Format:

```markdown
- [ ] Create git tag RALPH-YYYYMMDD-BEGIN
- [ ] First task
- [ ] Second task
- [ ] Third task
- [ ] Create git tag RALPH-YYYYMMDD-END
```

Rules:

- The first task is always: `Create git tag RALPH-YYYYMMDD-BEGIN` (use today's date)
- The last task is always: `Create git tag RALPH-YYYYMMDD-END` (use today's date)
- Each task is a single, independently-completable unit of work
- Tasks are ordered by dependency (earlier tasks unblock later ones)
- Use imperative voice
- Be specific enough that Claude can execute the task without ambiguity
- Reference specific files, modules, or components when relevant
- Do not include meta-tasks like "read the codebase" or "understand the architecture"
- ONLY put checkbox items in the task file. No other headings or prose.
- ONLY put task descriptions. Say *what* to do, not *how* to do it.
- Place documentation tasks (CLAUDE.md, .claude/docs/ updates) immediately after the code they document, not at the end of the task list

### Step 3: Build \_ralph-instructions.md

Write instructions that tell Claude how to accomplish the overall goal within this specific repo.

Format:

<!-- prettier-ignore-start -->
```markdown
# Ralph Instructions

## References

- @.claude/docs/architecture.md
- @.claude/docs/<other relevant docs>

## Goal

<one paragraph summary of the objective>

## Approach

<strategy specific to this goal — reference @.claude/docs docs, do not duplicate their content>

## Conventions

<repo-specific patterns, tools, test commands, build commands, commit style>

## Git Workflow

Before the first task:
  git checkout -b ralph/YYYYMMDD-<short-goal-slug>
  git tag RALPH-YYYYMMDD-BEGIN

After the last commit:
  git tag RALPH-YYYYMMDD-END

Never commit to main. All ralph work happens on the ralph/ branch.

## Per-Task Workflow

MANDATORY for every task without exception:
1. Write a failing test that defines the expected behavior
2. Write the minimum code to make the test pass
3. Refactor if needed while keeping tests green
4. git add and git commit with a conventional commit message
5. Mark the task [x] in _ralph-tasks.md

Never batch commits. Never skip the test step. Never skip the commit step.
```
<!-- prettier-ignore-end -->

Rules:

- Ground instructions in the actual repo structure and tooling
- Include build, test, and lint commands if known
- Do not duplicate the project's CLAUDE.md rules
- Define what "done" means for a task (tests pass, linter clean, etc.)
- Use `@path/file` syntax for all file references in the References section
- Do not duplicate content from existing .claude/docs/ files — reference them with @ syntax instead

### Step 4: Build \_ralph-prompt.md

Write exactly this static invocation. Do not modify it.

```markdown
/ralph-loop:ralph-loop "Read @.claude/docs/_ralph-instructions.md and follow its instructions. Work through @.claude/docs/_ralph-tasks.md one task at a time. Mark items [x] when complete. Output <promise>ALLDONE</promise> when all tasks are complete." --max-iterations 100 --completion-promise ALLDONE
```

Rules:

- The prompt text is fixed. Do not modify any part of it.
- Do not add `@` file references beyond `_ralph-instructions.md` and `_ralph-tasks.md`. All other file references belong in `_ralph-instructions.md`.

### Step 5: Report

List the three files created/updated and summarize the task count.

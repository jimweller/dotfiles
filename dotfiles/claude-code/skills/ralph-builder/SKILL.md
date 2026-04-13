---
name: ralph-builder
description: Build or update Ralph Wiggum loop files for autonomous task execution.
argument-hint: "<goal or filename>"
context: fork
disable-model-invocation: true
---

<!-- markdownlint-disable-file MD041 -->

STARTER_CHARACTER = 🔁

# Ralph Builder

Build or update the three Ralph Wiggum loop files in `.llmdocs/` so a ralph loop can execute autonomously against the current repo.

Arguments: $ARGUMENTS

The argument is a goal description. It may reference a file containing a PRD, plan, or task list.

## Output Files

All files go in `<PROJECT_ROOT>/.llmdocs/`. Create the directory if it does not exist.

| File               | Purpose                                         |
| ------------------ | ----------------------------------------------- |
| `_ralph-prompt.md` | The `/ralph-loop:ralph-loop` invocation command |
| `_ralph-tasks.md`  | Checklist of discrete tasks                     |
| `_ralph-plan.md`   | Execution plan for accomplishing the goal       |

## Procedure

### Step 1: Gather Context

Read these files to understand the repo:

1. `README.md` (project root)
2. All non-underscore `.md` files in `.llmdocs/` (architecture, api, data-model, deployment, testing, ops, etc.)
3. Any file referenced in $ARGUMENTS

If `.llmdocs/` does not exist, create it.

If `_ralph-tasks.md`, `_ralph-plan.md`, or `_ralph-prompt.md` already exist, read them before overwriting.

### Step 2: Build \_ralph-tasks.md

This file is a progress-tracking checklist for a loop that reads it cold each iteration with zero memory of previous runs. Each ralph-loop iteration scans this file to find the first unchecked `[ ]` item and works on it. Checked `[x]` items are the only signal of prior progress.

Each item names a deliverable or outcome. The task file answers "what's left?" -- never "how do I do it?" All implementation details (commands, patterns, techniques, function names) belong in `_ralph-plan.md`.

Format:

```markdown
- [ ] Create git tag RALPH-YYYYMMDD-BEGIN
- [ ] First task
- [ ] Second task
- [ ] Third task
- [ ] Create git tag RALPH-YYYYMMDD-END
```

BAD -- leaks implementation details into the task list:

```markdown
- [ ] Create lib/Test-Helpers.psm1 with Test-VmPath function
- [ ] Add Test-VmLogContains to lib/Test-Helpers.psm1
- [ ] Run `npm install jsonwebtoken bcrypt` and add to package.json
- [ ] Add middleware in src/middleware/auth.ts that validates Bearer tokens
```

GOOD -- names the deliverable, leaves technique to instructions:

```markdown
- [ ] Create lib/Test-Helpers.psm1
- [ ] Create lib/Test-Helpers.Tests.ps1
- [ ] Add auth dependencies
- [ ] Add auth middleware
```

Rules:

- The first task is always: `Create git tag RALPH-YYYYMMDD-BEGIN` (use today's date)
- The last task is always: `Create git tag RALPH-YYYYMMDD-END` (use same date as the RALPH BEGIN tag)
- Each task is a single, independently-completable unit of work
- The list is processed strictly top-to-bottom. Each iteration works the first unchecked `[ ]` item only, then marks it `[x]`. Order every task so that item N never depends on an uncompleted item below it
- Use imperative voice
- Reference specific files, modules, or components by name when it clarifies scope, but do not include commands, flags, config values, or implementation techniques
- Each task names a deliverable. If the item contains a shell command, a flag, a config value, or names a function/method, move that detail to `_ralph-plan.md`
- Do not include meta-tasks like "read the codebase" or "understand the architecture"
- Only checkbox items in the task file. No headings, prose, or blank lines between items.
- Place documentation tasks (CLAUDE.md, .llmdocs/ updates) immediately after the code they document, not at the end of the task list

### Step 3: Build \_ralph-plan.md

Each ralph-loop iteration reads this file cold with no memory of previous iterations. It must be fully self-contained: every command, pattern, convention, and technique needed to execute any task in `_ralph-tasks.md` belongs here. Dense, repo-specific detail is correct. Sparse, generic instructions cause each iteration to reinvent the approach.

The plan describes the target state and constraints, not the implementation. When existing code serves as a model, reference it by path. The model generates code through red-green-refactor during execution.

The plan is an execution guide, not a decision record. No rationale, changelogs, or "this replaces X" prose. State what exists and what to do with it. Each iteration doesn't care why a decision was made, only what the current state is and how to proceed.

BAD -- decision records and changelogs:

- SQL Server 2025 is GA and installs natively on Windows ARM64 without hacks. This replaces Docker SQL on macOS.
- The connectivity test changes from $SQL_SERVER (10.0.2.2 Docker gateway) to localhost.
- Finding 61: Get-WebBinding stringifies to type name.

GOOD -- current facts only:

- SQL Server 2025 runs natively on the VM. SQL_SERVER=localhost.
- Get-WebBinding returns an object. Access .bindingInformation or .protocol directly.

Format:

<!-- prettier-ignore-start -->
```markdown
# Ralph Plan

## Goal

<one paragraph summary of the objective>

## Approach

<strategy specific to this goal -- include all relevant repo-specific detail directly, do not reference external docs that may become stale during the run>

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

Each iteration: find the first unchecked `[ ]` item in _ralph-tasks.md. Work only that item. Do not skip ahead or batch multiple tasks.

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
- Include all relevant detail directly in the instructions file. Do not use `@path/file` references to .llmdocs/ docs -- ralph's work often changes the repo structure, making referenced docs stale mid-run

### Validation: cross-reference tasks and instructions

Before writing the files, verify the separation:

- For every task in `_ralph-tasks.md`, the instructions file must contain enough context to execute it (commands, patterns, file locations, conventions)
- If a task requires a specific command, pattern, or technique to execute, that detail lives in `_ralph-plan.md`, not on the task line
- If removing the task text and replacing it with just the deliverable name loses no actionable information, the task is correctly scoped. If it does lose information, move that information to the instructions file.

### Step 4: Build \_ralph-prompt.md

Write exactly this static invocation. Do not modify it.

```markdown
/ralph-loop:ralph-loop "Read @.llmdocs/\_ralph-plan.md and follow its instructions. Work through @.llmdocs/\_ralph-tasks.md one task at a time. Mark items [x] when complete. Output <promise>ALLDONE</promise> when all tasks are complete." --max-iterations 100 --completion-promise ALLDONE
```

Rules:

- The prompt text is fixed. Do not modify any part of it.
- Do not add `@` file references beyond `_ralph-plan.md` and `_ralph-tasks.md`. All other file references belong in `_ralph-plan.md`.

### Step 5: Report

List the three files created/updated and summarize the task count.

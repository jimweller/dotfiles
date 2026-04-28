---
name: ralph-review
description: Single-model deep review of the Ralph bd graph and plan via an in-process Claude opus subagent. Faster and cheaper than ralph-review-deep; lacks cross-model consensus.
context: fork
disable-model-invocation: true
---

<!-- markdownlint-disable-file MD041 -->

STARTER_CHARACTER = 🔍

# Ralph Review

Validate the beads graph and produce a single deep review of the ralph artifacts using Claude opus as a subagent via the `Agent` tool. Faster and cheaper than `ralph-review-deep` (which runs three models in parallel via opencode); same review framework, no cross-model consensus.

Use `ralph-review-deep` when single-model bias is a concern (high-stakes runs, contentious sequencing decisions). Use this skill for routine validation between iterations.

## Procedure

### Step 1: Validate Artifacts Exist

```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel)
```

Verify all of these exist:

- `$PROJECT_ROOT/.llmtmp/ralph-plan.md`
- `$PROJECT_ROOT/.llmtmp/ralph-prompt-insession.md`
- `$PROJECT_ROOT/.llmtmp/ralph-prompt-external.md`
- `$PROJECT_ROOT/.beads/` (directory; bd-aware probe via `bd list >/dev/null 2>&1`)

Abort if any are missing.

### Step 2: Validate the bd Graph

Run these checks before launching the subagent. Failures here are HIGH-severity findings and should abort or be flagged loudly.

The bd graph is organized under a per-run epic. The slug is derived from the current branch; the epic is found via the `ralph:<slug>` label. All scoped checks filter by `--parent ${EPIC}`.

```bash
cd "$PROJECT_ROOT"

SLUG=$(git branch --show-current | tr '/' '-')

# 1. Single open epic for this run
EPIC_COUNT=$(bd list -t epic -l "ralph:${SLUG}" --json 2>/dev/null | jq '[.[] | select(.status=="open")] | length')
if [[ "$EPIC_COUNT" -ne 1 ]]; then
  echo "HIGH: expected exactly one open epic with label ralph:${SLUG}, found ${EPIC_COUNT}"
fi
EPIC=$(bd list -t epic -l "ralph:${SLUG}" --json 2>/dev/null | jq -r '[.[] | select(.status=="open")] | .[0].id // empty')

# 2. Cycles
if ! bd dep cycles >/dev/null 2>&1; then
  echo "HIGH: bd graph has dependency cycles"
  bd dep cycles
fi

# 3. Minimum child count under the run epic
COUNT=$(bd list --parent "$EPIC" --json 2>/dev/null | jq 'length')
if [[ "$COUNT" -eq 0 ]]; then
  echo "HIGH: run epic ${EPIC} has no child tasks"
fi

# 4. At least one ready task under the run epic
READY_COUNT=$(bd ready --parent "$EPIC" --json 2>/dev/null | jq 'length')
if [[ "$READY_COUNT" -eq 0 && "$COUNT" -gt 0 ]]; then
  echo "HIGH: run epic ${EPIC} has tasks but no ready tasks (deadlock or all closed unexpectedly)"
fi

# 5. Isolated nodes within the run epic
if [[ "$COUNT" -gt 1 ]]; then
  bd list --parent "$EPIC" --json 2>/dev/null \
    | jq -r '.[] | select(.dependency_count == 0 and .dependent_count == 0) | "MEDIUM: isolated task " + .id + " " + .title'
fi

# 6. Description coverage: every child carries the worker's instructions
bd list --parent "$EPIC" --json 2>/dev/null \
  | jq -r '.[] | select(((.description // "") | length) == 0) | "HIGH: task " + .id + " has empty description: " + .title'

# 7. Parent set equals label set (defense-in-depth orphan detection)
PARENT_IDS=$(bd list --parent "$EPIC" --json 2>/dev/null | jq -r '.[].id' | sort)
LABEL_IDS=$(bd list --label "ralph:${SLUG}" --json 2>/dev/null | jq -r '.[] | select(.issue_type != "epic") | .id' | sort)
if [[ "$PARENT_IDS" != "$LABEL_IDS" ]]; then
  echo "HIGH: parent set (--parent ${EPIC}) and label set (--label ralph:${SLUG} excluding epic) differ"
  echo "Parent-only (label missing): $(comm -23 <(echo "$PARENT_IDS") <(echo "$LABEL_IDS"))"
  echo "Label-only (orphan, parent missing): $(comm -13 <(echo "$PARENT_IDS") <(echo "$LABEL_IDS"))"
fi
```

Persist these findings; the subagent references them in its final report.

### Step 3: Clean Up Previous Review

```bash
rm -f "$PROJECT_ROOT/.llmtmp/ralph-review.md"
```

### Step 4: Read Files and Build Prompt Context

Concatenate the contents of these files into a single `CONTEXT` string:

1. `.llmtmp/ralph-plan.md`
2. `.llmtmp/ralph-prompt-insession.md`
3. `.llmtmp/ralph-prompt-external.md`
4. The slug and epic ID resolved in Step 2 (literal label `SLUG=...` and `EPIC=...`)
5. Output of `bd list --parent "$EPIC" --json`
6. Output of `bd ready --parent "$EPIC" --json`
7. Output of `bd list --label "ralph:${SLUG}" --json`
8. The bd graph validation findings from Step 2
9. Plan documents listed in the plan's `plan documents:` line. Parse the line, split on commas, trim whitespace, read each path. Wrap each as `=== plan-documents/<path> ===` so the reviewer can distinguish them from baseline. Empty value means no plan documents to load.
10. `CLAUDE.md` and `README.md` from project root (if they exist)
11. All `.md` files in `.llmdocs/`

Wrap each as:

```text
=== <relative-path or label> ===
<contents>
```

### Step 5: Launch the Opus Subagent

Invoke the `Agent` tool with:

- `subagent_type`: `general-purpose`
- `model`: `opus`
- `description`: `"Ralph plan deep review"`
- `prompt`: the prompt template below, with `<PROJECT_ROOT>` and `<CONTEXT>` substituted

The subagent runs in-process and writes `.llmtmp/ralph-review.md` directly via the Write tool.

```text
PROMPT="You are a plan reviewer. Output a single review file at <PROJECT_ROOT>/.llmtmp/ralph-review.md and nothing else. Do not summarize the file content in your final response; only confirm the file was written.

PROJECT_ROOT: <PROJECT_ROOT>

## Context

<CONTEXT>

## Authority sources in CONTEXT

The CONTEXT contains two distinct authority categories. Treat them differently.

- **Plan documents** (under `=== plan-documents/...` blocks): forward-looking intent the planner consulted, e.g., a PRD, a Jira ticket, a design note. The plan must faithfully render these. Flag the plan if it omits, contradicts, or stale-references a requirement from a plan document.
- **Baseline docs** (`CLAUDE.md`, `README.md`, `.llmdocs/*`): the system's current state. The plan's job is to change this state. Do NOT flag the plan for deviating from baseline. Flag only if the plan changes baseline without including a corresponding docs-update bead (typically delegated to `/docs`).

## How Ralph Loops Work

A ralph loop is an autonomous, iterative execution mechanism. Two execution modes share the same artifacts:

- **In-session (ralph-loop plugin)**: a Stop hook re-feeds the prompt to the same Claude session. Cheap on short runs; expensive on long runs because context grows quadratically.
- **External (scripts/ralph.sh)**: a bash while-loop spawns a fresh `claude --print` per iteration. Higher fixed overhead per iteration; stays in the cheap part of the cost curve indefinitely.

Mechanics that apply to both modes:

- The bd graph is the state machine. The graph is shared across worktrees of the same repo. Each ralph run is organized under a per-run epic so concurrent runs in different worktrees stay isolated by `--parent` filtering. `bd ready --parent <epic> --json` finds the next unblocked task within this run.
- The run epic carries the label `ralph:<slug>` where `<slug>` is derived from the current branch. Every child task carries both `--parent <epic>` and the same `ralph:<slug>` label. The two signals are independent so the reviewer can detect orphans.
- The plan's "Run Identity" section records the literal slug and epic ID. The agent reads them directly from the plan each iteration, no derivation.
- One task per iteration. The agent reads `bd ready --parent <epic> --json`, takes the first result, runs the per-task workflow, then closes the task.
- When the ready queue is empty, the agent closes the epic and emits the sentinel as the terminal action. The epic is not closed by `bd` automatically.
- Resumable. A partially-completed graph resumes cleanly. Partial completion is normal; iterations are cheap.
- Every action is a bd task, including ralph lifecycle scaffolding. The branch creation, BEGIN tag, code work, docs, and END tag are all first-class beads, all parented to the run epic.
- Each bead carries its full per-task instructions in its description: files to touch, expected behavior, verification command, commit message. The worker reads `bd show <id>` and executes the description exactly.
- Run-wide conventions (commit style, language, build command, test command) live in `ralph-plan.md`, not in every description.
- Environment is a precondition. Credentials, network, toolchain, and runtime dependencies are the operator's responsibility. Do not flag missing environment setup as a gap.

Do NOT recommend: collapsing tasks into bundles, adding environment preflight checks, treating partial completion as a risk, modifying the prompt body, replacing the bd graph with a markdown checklist, or reintroducing a workflow-label taxonomy. The `ralph:<slug>` label is run-identity for partition and orphan detection, not workflow dispatch; do not flag it as a label taxonomy.

Flag as HIGH severity if: zero or more than one open epic exists for `ralph:<slug>`; any open child has an empty description; the bd graph contains cycles; the run epic has no children; the run epic has children but no ready tasks; the parent set under the epic differs from the label set for `ralph:<slug>` (orphans or planning typos); the per-task workflow does not explicitly stop after `bd close` (the agent will do multiple beads in one context, defeating the Ralph design); the per-task workflow does not close the epic before emitting the sentinel; the plan lacks a 'Run Identity' section recording the literal slug and epic ID; the plan lacks an 'Inputs' section with a `plan documents:` line; the plan omits or contradicts a material requirement explicit in any plan document; the plan's Approach prose declares an ordering ('X first', 'after Y') that the bd dependency edges do not enforce. Flag as MEDIUM if: a description omits the verification command or commit message; an isolated task exists in a multi-task graph; the plan duplicates information that already lives in bead descriptions; a bead that touches README.md/CLAUDE.md/.llmdocs/ authors edits inline instead of running `/docs`.

## Your Task

Review the Ralph artifacts:

- ralph-plan.md (mode-neutral execution plan)
- ralph-prompt-insession.md (slash-command wrapper for the in-session driver)
- ralph-prompt-external.md (body for scripts/ralph.sh)
- The bd graph (issues, dependencies, ready/closed state)

Evaluate across these areas:

### 1. Goal Clarity

- Is the objective well-defined and unambiguous?
- Would a fresh-context iteration understand what success looks like from the plan alone?

### 2. Task Decomposition

- Are tasks the right granularity (one focused deliverable each)?
- Is each task independently completable?
- Are there missing tasks needed to achieve the goal?
- Are there unnecessary or redundant tasks?
- Do titles name deliverables rather than techniques?
- Do descriptions carry enough detail (files, verification, commit message) for a cold-start worker?

### 3. Sequencing and Dependencies

- Are dependencies correct in the bd graph?
- Would executing in `bd ready --json` order produce correct results?
- Are there implicit dependencies that should be explicit edges?
- Are there cycles or isolated nodes?

### 4. Plan Completeness

- Do the instructions cover repo-specific conventions, tools, and commands?
- Are build, test, and lint commands accurate?
- Is the per-task workflow clear (read description, execute it, close)?
- Does the plan have a 'Run Identity' section that records the literal branch slug, the literal epic ID, and the epic label `ralph:<slug>`?
- Does the Per-Task Workflow read the epic ID from the 'Run Identity' section and scope `bd ready` with `--parent <epic-id>`?
- Does the Per-Task Workflow close the epic via `bd close <epic-id>` before emitting the sentinel when the ready queue is empty?
- Does the Per-Task Workflow explicitly say STOP after `bd close` so the agent does not loop within a single context?
- Does the Git Workflow section require a `ralph/` feature branch and BEGIN/END tags?
- Is the Per-Task Workflow explicit that `bd close` for the current task runs BEFORE the sentinel?
- Do beads that touch `README.md`, `CLAUDE.md`, or `.llmdocs/` invoke the `/docs` skill rather than authoring edits inline?

### 5. Risk and Gaps

- What could go wrong during autonomous execution?
- Are there tasks that require human judgment or external access?
- Could any task leave the repo in a broken state?

### 6. Feasibility

- Can a single iteration realistically complete each task?
- Are there tasks that exceed what a fresh context can do autonomously?

For each area, list specific findings with severity (high/medium/low) and actionable recommendations.

## Output

Write to `<PROJECT_ROOT>/.llmtmp/ralph-review.md` using this template:

\`\`\`markdown
# Ralph Loop Review
**Model**: claude-opus

## Goal Clarity

- **[medium]** Short title. Explanation...

## Task Decomposition

- **[high]** Short title. Explanation...

## Sequencing and Dependencies

- **[medium]** Short title. Explanation...

## Plan Completeness

- **[low]** Short title. Explanation...

## Risk and Gaps

- **[high]** Short title. Explanation...

## Feasibility

- **[medium]** Short title. Explanation...

## Summary

<overall assessment and top 3 recommendations>
\`\`\`

Finding format: \`- **[severity]** Title. Description.\`

Every section must be present. If no findings for an area, write 'No findings.' under its heading.

After writing the file, verify it exists with the Bash tool: \`ls -la '<PROJECT_ROOT>/.llmtmp/ralph-review.md'\`. If absent, write it again. Do not exit without the file."
```

### Step 6: Verify Output

```bash
ls -la "$PROJECT_ROOT/.llmtmp/ralph-review.md"
```

If the file is missing, the subagent failed. Retry the Agent invocation once. If the second attempt also fails, report the failure to the user and stop.

### Step 7: Report Results

Read `.llmtmp/ralph-review.md`. Surface:

- The bd graph validation findings from Step 2 at the top
- The HIGH-severity findings from each section
- The Summary section verbatim

Do not paraphrase the review body; the subagent's wording is the deliverable.

## Expected Output Files

One file:

- `.llmtmp/ralph-review.md`

## Rules

- Claude Code is the launcher. The deep review work happens inside the opus subagent.
- The bd graph validation in Step 2 runs in Claude Code, not in the subagent. Findings are passed to the subagent as context.
- Do not perform any review analysis directly in the launcher session. Synthesize only at report time (Step 7).
- The Agent invocation must specify `model: opus`. Default sonnet is insufficient for the depth this skill targets.
- If the bd graph has HIGH-severity structural failures (cycles, missing epic, parent/label mismatch), do not invoke the subagent; report the failures directly. The plan is not reviewable until the graph is sound.

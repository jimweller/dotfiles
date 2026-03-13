---
name: ralph-reviewer
description: Review Ralph Wiggum loop files using three models in parallel via opencode run.
user-invocable: true
---

STARTER_CHARACTER = 🔍

# Ralph Reviewer

Launch 3 independent plan reviews of the Ralph Wiggum loop files in parallel using different models via `opencode run`. Each model produces one review file evaluating the ralph loop's goal clarity, task decomposition, sequencing, instructions completeness, risk/gaps, and feasibility.

## Models

| Label   | Model ID                        |
|---------|---------------------------------|
| openai  | openai/gpt-5.3-codex            |
| gemini  | google/gemini-3.1-pro-preview   |
| claude  | az-anthropic/claude-opus-4-6    |

## Procedure

### Step 1: Validate Ralph Files Exist

```
PROJECT_ROOT=$(git rev-parse --show-toplevel)
```

Verify these files exist in `$PROJECT_ROOT/.llmdocs/`:
- `_ralph-prompt.md`
- `_ralph-tasks.md`
- `_ralph-instructions.md`

Abort if any are missing.

### Step 2: Clean Up Previous Reviews

```bash
rm -f "$PROJECT_ROOT"/.llmdocs/_review-ralph-openai.md \
      "$PROJECT_ROOT"/.llmdocs/_review-ralph-gemini.md \
      "$PROJECT_ROOT"/.llmdocs/_review-ralph-claude.md
```

### Step 3: Read Files and Build Prompt Content

Read these files and concatenate their contents into a single `CONTEXT` string:

1. The three ralph files (underscore-prefixed but explicitly included): `.llmdocs/_ralph-prompt.md`, `.llmdocs/_ralph-tasks.md`, `.llmdocs/_ralph-instructions.md`
2. `CLAUDE.md` and `README.md` from project root (if they exist)
3. All other `.md` files in `.llmdocs/` that do NOT start with `_` (architecture, api, data-model, etc.)

For each file, wrap it as:

```
=== <relative-path> ===
<file contents>
```

### Step 4: Construct the Review Prompt

Build the prompt that each opencode process will execute. Replace `<PROJECT_ROOT>` with the resolved value and `<CONTEXT>` with the concatenated file contents from step 3.

```
PROMPT="You are a plan reviewer running headless in a non-interactive session. There is no user present. Do not ask questions. Do not prompt for confirmation. Do not stop to wait for input.

YOUR PRIMARY OBJECTIVE IS TO WRITE A FILE. Everything else is preparation. After completing your review, your VERY NEXT action must be a bash tool call that writes the output file using cat with a heredoc. Do not summarize, do not reflect, do not plan — write the file immediately.

OUTPUT RULES: You are running headless. Nobody reads your text responses. NEVER print findings, analysis, or review content as text output. ALL review content goes exclusively into the file via bash heredoc. Any text you generate outside of a tool call is wasted tokens and risks hitting the output token limit before you can write the file. Keep text responses to one short sentence at most.

PROJECT_ROOT: <PROJECT_ROOT>

## Context

<CONTEXT>

## How Ralph Loops Work

A ralph loop is an autonomous, iterative execution mechanism for Claude. Understand these mechanics before reviewing:

- **One task per iteration.** Claude picks the next unchecked `[ ]` item, completes it, marks it `[x]`, and the loop advances. Fine-grained tasks are intentional.
- **Resumable.** If the loop hits max-iterations, the user re-runs it. Partial completion is expected and normal. The checklist is the progress bookmark.
- **Checklist is the state machine.** `[x]` marks are how the loop knows where to resume. This is not bookkeeping overhead; it is the core mechanism.
- **No commits.** Ralph does not commit. The user reviews and commits after the loop completes or pauses.
- **Environment is a precondition.** Credentials, network, toolchain, and runtime dependencies are the user's responsibility. Ralph assumes they are present. Do not flag missing environment setup as a gap.
- **London TDD granularity is correct.** Failing test, code, passing test per task is the intended workflow. Do not recommend collapsing these into larger bundles.
- **Iterations are cheap.** Do not recommend reducing task count to fit within max-iterations. The user adjusts max-iterations or re-runs.

Do NOT recommend: collapsing tasks into bundles, adding commit policies, adding environment preflight checks, reducing granularity to avoid iteration exhaustion, or treating partial completion as a risk.

## Your Task

Review the Ralph Wiggum loop plan defined by three files:
- _ralph-prompt.md (the loop invocation command)
- _ralph-tasks.md (the task checklist)
- _ralph-instructions.md (execution instructions)

Evaluate the plan across these areas:

### 1. Goal Clarity
- Is the objective well-defined and unambiguous?
- Would Claude understand what success looks like?

### 2. Task Decomposition
- Are tasks the right granularity (not too broad, not too fine)?
- Is each task independently completable?
- Are there missing tasks needed to achieve the goal?
- Are there unnecessary or redundant tasks?

### 3. Sequencing and Dependencies
- Are tasks ordered correctly by dependency?
- Would executing in order produce correct results?
- Are there implicit dependencies that should be explicit?

### 4. Instructions Completeness
- Do the instructions cover repo-specific conventions, tools, and commands?
- Are build/test/lint commands accurate?
- Is the per-task workflow clear (what to do, how to verify, how to mark done)?
- Are the file references in the instructions accurate and sufficient?

### 5. Risk and Gaps
- What could go wrong during autonomous execution?
- Are there tasks that require human judgment or external access?
- Are there missing error recovery instructions?
- Could any task leave the repo in a broken state?

### 6. Feasibility
- Can Claude realistically complete each task within a single ralph loop iteration?
- Is the max-iterations setting appropriate for the task count?
- Are there tasks that exceed what Claude can do autonomously?

For each area, list specific findings with severity (high/medium/low) and actionable recommendations.

## Output — DO THIS IMMEDIATELY AFTER COMPLETING YOUR REVIEW

Your VERY NEXT action after finishing the review must be a bash call that writes the file. No intermediate steps.

Determine your model label:
- Claude variants: claude
- GPT variants: openai
- Gemini variants: gemini

Write your review to: <PROJECT_ROOT>/.llmdocs/_review-ralph-\$MODEL_LABEL.md

Use bash with a heredoc. Follow this template exactly:

```
cat > '<PROJECT_ROOT>/.llmdocs/_review-ralph-<MODEL_LABEL>.md' <<'REVIEW_EOF'
# Ralph Loop Review
**Model**: <MODEL_LABEL>

## Goal Clarity

- **[medium]** Short title. Explanation of the finding...

## Task Decomposition

- **[high]** Short title. Explanation...
- **[low]** Short title. Explanation...

## Sequencing and Dependencies

- **[medium]** Short title. Explanation...

## Instructions Completeness

- **[low]** Short title. Explanation...

## Risk and Gaps

- **[high]** Short title. Explanation...

## Feasibility

- **[medium]** Short title. Explanation...

## Summary

<overall assessment and top 3 recommendations>
REVIEW_EOF
```

Finding format: `- **[severity]** Title. Description.`

Every section must be present. If no findings for an area, write 'No findings.' under its heading.

Then verify: ls -la '<PROJECT_ROOT>/.llmdocs/_review-ralph-<MODEL_LABEL>.md'

If the file does not exist, write it again. Do not exit without the file."
```

### Step 5: Write Prompt to File

Write the prompt string to a temp file. This avoids shell interpolation issues with large prompts.

```bash
STATE_DIR="$PROJECT_ROOT/.llmdocs/ralph_review_state"
mkdir -p "$STATE_DIR"
OPENAI_DIR=$(mktemp -d)
GEMINI_DIR=$(mktemp -d)
CLAUDE_DIR=$(mktemp -d)
cat > /tmp/ralph-review-prompt.txt <<'PROMPT_EOF'
<the prompt from step 4>
PROMPT_EOF
```

### Step 6: Launch 3 Separate Background Bash Tasks

Launch each opencode process as its own separate background Bash task. Do NOT launch all 3 in a single shell — child processes get killed when the parent shell exits.

Each is a separate Bash call with `run_in_background`:

**OpenAI:**
```bash
STATE_DIR="<PROJECT_ROOT>/.llmdocs/ralph_review_state" && \
opencode run \
  -m openai/gpt-5.3-codex \
  --format json \
  --print-logs \
  --log-level INFO \
  --dir "<OPENAI_DIR>" \
  --title "Ralph Review - OpenAI" \
  "$(cat /tmp/ralph-review-prompt.txt)" \
  > "$STATE_DIR/openai.ndjson" 2>"$STATE_DIR/openai.log"
```

**Gemini:**
```bash
STATE_DIR="<PROJECT_ROOT>/.llmdocs/ralph_review_state" && \
opencode run \
  -m google/gemini-3.1-pro-preview \
  --format json \
  --print-logs \
  --log-level INFO \
  --dir "<GEMINI_DIR>" \
  --title "Ralph Review - Gemini" \
  "$(cat /tmp/ralph-review-prompt.txt)" \
  > "$STATE_DIR/gemini.ndjson" 2>"$STATE_DIR/gemini.log"
```

**Claude:**
```bash
STATE_DIR="<PROJECT_ROOT>/.llmdocs/ralph_review_state" && \
opencode run \
  -m az-anthropic/claude-opus-4-6 \
  --format json \
  --print-logs \
  --log-level INFO \
  --dir "<CLAUDE_DIR>" \
  --title "Ralph Review - Claude" \
  "$(cat /tmp/ralph-review-prompt.txt)" \
  > "$STATE_DIR/claude.ndjson" 2>"$STATE_DIR/claude.log"
```

All 3 must be launched in parallel as separate background tasks. Do NOT use `&` in a single shell.

#### Output Streams

Each opencode process produces two output files:

- **`<label>.ndjson`** (stdout): Structured NDJSON events from `--format json`. Use for programmatic progress tracking (step counts, cost, tool calls, completion detection).
- **`<label>.log`** (stderr): Plain-text info-level logs from `--print-logs --log-level INFO`. Use for diagnosing startup failures, permission issues, MCP server errors, and plugin loading problems.

Log lines are structured text, one per line:
```
INFO  2026-03-13T00:54:25 +4ms service=default directory=/private/tmp creating instance
```

### Step 7: Monitor and Wait

Poll each background task until all 3 complete.

**NDJSON progress** — replace `$NDJSON` with the actual path (e.g., `<PROJECT_ROOT>/.llmdocs/ralph_review_state/openai.ndjson`):

```bash
# Count completed steps for a model
grep -c '"type":"step_finish"' "$NDJSON" 2>/dev/null || echo 0

# Check if done (last step_finish has reason: "stop")
tail -1 "$NDJSON" 2>/dev/null | jq -r '.part.reason // empty'

# Check for errors in NDJSON events
grep '"type":"error"' "$NDJSON" 2>/dev/null
```

**Text logs** — replace `$LOGFILE` with the actual path (e.g., `<PROJECT_ROOT>/.llmdocs/ralph_review_state/openai.log`):

```bash
# Check for errors or warnings in text logs
grep -E "^(ERROR|WARN)" "$LOGFILE" 2>/dev/null

# Tail recent log activity
tail -5 "$LOGFILE" 2>/dev/null
```

### Step 8: Report Results

For each model, check if its expected output file exists at `.llmdocs/_review-ralph-<label>.md`.

Report per model:
- Success/failure (output file present or not)
- Total cost (sum of `cost` from all `step_finish` events)
- Whether any errors occurred

### Step 9: Cleanup

```bash
rm -rf "$STATE_DIR"
rm -f /tmp/ralph-review-prompt.txt
```

## Expected Output Files

3 files total, one per model:

- `.llmdocs/_review-ralph-openai.md`
- `.llmdocs/_review-ralph-gemini.md`
- `.llmdocs/_review-ralph-claude.md`

## NDJSON Log Format Reference

Each opencode process writes NDJSON to `$STATE_DIR/<label>.ndjson`. One JSON object per line. Skip lines that fail to parse (partial writes).

Key event types:

- **step_start** - New LLM turn begins.
- **text** - Model emitted text: `{"type":"text","part":{"text":"..."}}`
- **tool_use** - Tool call: `{"type":"tool_use","part":{"tool":"bash","state":{"status":"completed","metadata":{"exit":0}}}}`
- **step_finish** - Turn completed: `{"type":"step_finish","part":{"reason":"stop","cost":0,"tokens":{"total":13494}}}`. `reason: "stop"` = done, `reason: "tool-calls"` = continuing.
- **error** - Session error: `{"type":"error","error":{"data":{"message":"..."}}}`

Useful jq queries (replace `$NDJSON` with actual path, e.g., `<PROJECT_ROOT>/.llmdocs/ralph_review_state/openai.ndjson`):

```bash
NDJSON="<PROJECT_ROOT>/.llmdocs/ralph_review_state/openai.ndjson"
# Is done?
tail -1 "$NDJSON" | jq -r 'select(.type=="step_finish") | .part.reason'
# Total cost
jq -s '[.[] | select(.type=="step_finish") | .part.cost] | add' "$NDJSON"
# All errors from NDJSON events
jq -r 'select(.type=="error") | .error.data.message' "$NDJSON"
```

Replace `$LOGFILE` with the text log path (e.g., `<PROJECT_ROOT>/.llmdocs/ralph_review_state/openai.log`):

```bash
# All errors and warnings from text logs
grep -E "^(ERROR|WARN)" "$LOGFILE"
```

## Rules

- Claude Code is ONLY a launcher. All review work happens inside the opencode processes.
- Do NOT perform any review analysis directly. The opencode processes handle reviewing.
- Do NOT ask questions during execution. This is non-interactive.
- Launch all 3 processes in parallel. Do not wait for one to finish before starting another.
- Use plain message invocation, not `--command`. The `--command` flag has a known issue with the c7 MCP server.
- Clean up the state directory after reporting results.
- If a model fails, still wait for and report the others.

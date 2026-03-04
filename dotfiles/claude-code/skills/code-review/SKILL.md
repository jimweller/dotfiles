---
name: code-review
description: Launch parallel code reviews using OpenAI, Gemini, and Claude via opencode run.
user-invokable: true
argument-hint: "<path>"
---

STARTER_CHARACTER = 🕵️‍♂️

# Code Review Skill

Launch 3 independent code reviews in parallel using different models via `opencode run`. Claude Code packs repomix once, then each model spawns 8 review-* subagents that navigate the packed output via MCP. Each model produces one combined review file.

Arguments: $ARGUMENTS

## Models

| Label   | Model ID                        |
|---------|---------------------------------|
| openai  | openai/gpt-5.3-codex            |
| gemini  | google/gemini-3-flash-preview   |
| claude  | az-anthropic/claude-opus-4-6    |

## Procedure

### Step 1: Resolve Target and Clean Up

```
TARGET_PATH = $ARGUMENTS (or repo root if empty)

If TARGET_PATH is empty or not provided: use git repo root.
Otherwise: resolve as relative path from repo root.

Derive TARGET_NAME from last path segment, or "repo" if root.
```

Validate the target directory exists. Abort if not.

Delete previous review files and ensure output directory:

```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel)
rm -f "$PROJECT_ROOT"/.llmdocs/_review-"$TARGET_NAME"-openai.md \
      "$PROJECT_ROOT"/.llmdocs/_review-"$TARGET_NAME"-gemini.md \
      "$PROJECT_ROOT"/.llmdocs/_review-"$TARGET_NAME"-claude.md
mkdir -p "$PROJECT_ROOT/.llmdocs"
```

### Step 2: Pack Repomix

Pack the target using the repomix CLI. This avoids the MCP tool's large result payload which
triggers a confusing truncation error in Claude Code's UI on large repos.

```bash
REPOMIX_FILE="/tmp/repomix-review-$TARGET_NAME.xml"
npx repomix -o "$REPOMIX_FILE" --quiet "$TARGET_PATH"
```

Repomix reads `.repomixignore` from the project root automatically.

Verify the file was created, then confirm `REPOMIX_FILE` to the user before proceeding.

### Step 3: Construct the Orchestrator Prompt

Build the prompt that each opencode process will execute. Replace `<TARGET_PATH>`, `<TARGET_NAME>`, `<PROJECT_ROOT>`, and `<REPOMIX_FILE>` with the resolved values.

```
PROMPT="You are a code review orchestrator. Execute this procedure non-interactively. Do not ask questions.

TARGET_PATH: <TARGET_PATH>
TARGET_NAME: <TARGET_NAME>
REPOMIX_FILE: <REPOMIX_FILE>

CRITICAL: The repository is ALREADY packed. Do NOT call pack_codebase or repomix yourself.
The file at REPOMIX_FILE is ready to use. Pass it to subagents as repomix_file.

## Step 1: Spawn Review Agents

Spawn ALL 8 review-* subagents in PARALLEL, one per area.
Each agent prompt MUST include: repomix_file=<REPOMIX_FILE>

Areas: security, architecture, solid, correctness, testing, ops, performance, quality.

Each agent will:
1. Call attach_packed_output with REPOMIX_FILE to get an outputId
2. Use read_repomix_output and grep_repomix_output to navigate the codebase
3. Return findings as text

Agents are read-only (write: false). They return text output, not files.
Do NOT pack the repository. Do NOT call pack_codebase. It is already packed.

## Step 2: Collect Results

After all 8 agents complete, collect their text output.

## Step 3: Determine Model Label

Derive a short lowercase label for your model identity:
- Claude variants: claude
- GPT variants: openai
- Gemini variants: gemini

## Step 4: Write Combined Review

Write ONE combined markdown file containing all 8 agents' findings:

<PROJECT_ROOT>/.llmdocs/_review-<TARGET_NAME>-\$MODEL_LABEL.md

Format:
# Code Review: <TARGET_NAME>
**Model**: \$MODEL_LABEL

Then for each area, include a section:
## <Area Title>
<agent findings>

Area titles: Security, Architecture & Design, SOLID Principles, Correctness & Bugs, Testing, Operational Readiness, Performance, Code Quality.

If an agent returned 'No findings.', include that under its section.

## Step 5: Report

List the output file created."
```

### Step 4: Launch 3 Background Processes

Launch all 3 opencode processes in parallel using background Bash tasks. Each writes NDJSON output to a log file.

```bash
STATE_DIR="$PROJECT_ROOT/.llmdocs/multi_review_state"
mkdir -p "$STATE_DIR"
```

```bash
opencode run \
  -m openai/gpt-5.3-codex\
  --format json \
  --title "Review - OpenAI" \
  "$PROMPT" \
  > "$STATE_DIR/openai.ndjson" 2>&1 &
echo $!
```

```bash
opencode run \
  -m google/gemini-3-flash-preview \
  --format json \
  --title "Review - Gemini" \
  "$PROMPT" \
  > "$STATE_DIR/gemini.ndjson" 2>&1 &
echo $!
```

```bash
opencode run \
  -m az-anthropic/claude-opus-4-6 \
  --format json \
  --title "Review - Claude" \
  "$PROMPT" \
  > "$STATE_DIR/claude.ndjson" 2>&1 &
echo $!
```

Capture the 3 PIDs.

### Step 5: Wait and Report

Wait for all 3 PIDs to exit. Use `wait $PID1 $PID2 $PID3` or poll with `kill -0`.

For each model, check if its expected output file exists at `.llmdocs/_review-<TARGET_NAME>-<label>.md`.

Report which models succeeded (file present) and which failed (file missing).

### Step 6: Cleanup

```bash
rm -rf "$STATE_DIR"
```

## Expected Output Files

3 files total, one per model:

- `.llmdocs/_review-<TARGET_NAME>-openai.md`
- `.llmdocs/_review-<TARGET_NAME>-gemini.md`
- `.llmdocs/_review-<TARGET_NAME>-claude.md`

Where `<TARGET_NAME>` is derived from the path's last segment (or `repo` for root).

## NDJSON Log Format Reference

Each opencode process writes NDJSON to `$STATE_DIR/<label>.ndjson`. Each line is a JSON object. Key event types:

- `{"type": "step_finish", "part": {"cost": 0.0012, "tokens": {"total": 17311}, "reason": "stop"|"tool-calls"}}` -- step completed; `reason: "stop"` on the final event means the model finished.
- `{"type": "tool_use", "part": {"tool": "bash", "state": {"status": "completed"|"error"}}}` -- tool invocation.
- `{"type": "error", "error": {"data": {"message": "..."}}}` -- error occurred.

Skip lines that fail to parse (partial writes).

## Rules

- Claude Code is ONLY a launcher. All review work happens inside the opencode processes.
- Do NOT perform any review analysis directly. The opencode processes handle reviewing.
- Do NOT ask questions during execution. This is non-interactive.
- Launch all 3 processes in parallel. Do not wait for one to finish before starting another.
- Use plain message invocation, not `--command`. The `--command` flag has a known issue with the c7 MCP server.
- Clean up the state directory after reporting results.
- If a model fails, still wait for and report the others.

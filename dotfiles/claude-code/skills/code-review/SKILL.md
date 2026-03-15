---
name: code-review
description: Launch parallel code reviews using OpenAI, Gemini, and Claude via opencode run.
user-invocable: true
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
| gemini  | google/gemini-3.1-pro-preview   |
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
npx repomix -o "$REPOMIX_FILE" --quiet --output-show-line-numbers "$PROJECT_ROOT/$TARGET_PATH"
```

Repomix reads `.repomixignore` from the project root automatically.

Verify the file was created, then confirm `REPOMIX_FILE` to the user before proceeding.

### Step 3: Construct the Orchestrator Prompt

Build the prompt that each opencode process will execute. Replace `<TARGET_PATH>`, `<TARGET_NAME>`, `<PROJECT_ROOT>`, and `<REPOMIX_FILE>` with the resolved values.

```
PROMPT="You are a code review orchestrator running headless in a non-interactive session. There is no user present. Do not ask questions. Do not prompt for confirmation. Do not stop to wait for input.

YOUR PRIMARY OBJECTIVE IS TO WRITE A FILE. Everything else is preparation. If you complete the subagent work but fail to write the output file, the entire session is a failure. After collecting subagent results, your VERY NEXT action must be a bash tool call that writes the output file using cat with a heredoc. Do not summarize, do not reflect, do not plan — write the file immediately.

OUTPUT RULES: You are running headless. Nobody reads your text responses. NEVER print findings, analysis, or review content as text output. ALL review content goes exclusively into the file via bash heredoc. Any text you generate outside of a tool call is wasted tokens and risks hitting the output token limit before you can write the file. Keep text responses to one short sentence at most.

TARGET_PATH: <TARGET_PATH>
TARGET_NAME: <TARGET_NAME>
REPOMIX_FILE: <REPOMIX_FILE>

CRITICAL: The repository is ALREADY packed. Do NOT call pack_codebase or repomix yourself.
The file at REPOMIX_FILE is ready to use. Pass it to subagents as repomix_file.

## A. Spawn Review Agents

Spawn ALL 8 review-* subagents in PARALLEL, one per area.
Each agent prompt MUST include: repomix_file=<REPOMIX_FILE>

Areas: security, architecture, solid, correctness, testing, ops, performance, quality.

Each agent will:
1. Call attach_packed_output with REPOMIX_FILE to get an outputId
2. Use read_repomix_output and grep_repomix_output to navigate the codebase
3. Return findings as text

Agents are read-only (write: false). They return text output, not files.
Do NOT pack the repository. Do NOT call pack_codebase. It is already packed.

## B. Collect Results

After all 8 agents complete, collect their text output.

## C. Determine Model Label

Derive a short lowercase label for your model identity:
- Claude variants: claude
- GPT variants: openai
- Gemini variants: gemini

## D. Write Combined Review — DO THIS IMMEDIATELY AFTER COLLECTING RESULTS

Your VERY NEXT action after collecting subagent results must be a bash call that writes the file. No intermediate steps.

Write ONE combined markdown file containing all 8 agents' findings:

<PROJECT_ROOT>/.llmdocs/_review-<TARGET_NAME>-\$MODEL_LABEL.md

Use bash with a heredoc. Follow this template exactly:

```
cat > '<PROJECT_ROOT>/.llmdocs/_review-<TARGET_NAME>-<MODEL_LABEL>.md' <<'REVIEW_EOF'
# Code Review: <TARGET_NAME>
**Model**: <MODEL_LABEL>

## Security

- **[high]** `path/to/file:line` — Short title. Explanation of the finding...
- **[low]** `path/to/file:line` — Short title. Explanation...

## Architecture & Design

- **[medium]** `path/to/file:line` — Short title. Explanation...

## SOLID Principles

- **[medium]** `path/to/file:line` — Short title. Explanation...

## Correctness & Bugs

- **[high]** `path/to/file:line` — Short title. Explanation...

## Testing

- **[medium]** `path/to/file:line` — Short title. Explanation...

## Operational Readiness

- **[low]** `path/to/file:line` — Short title. Explanation...

## Performance

- **[medium]** `path/to/file:line` — Short title. Explanation...

## Code Quality

- **[low]** `path/to/file:line` — Short title. Explanation...
REVIEW_EOF
```

Finding format: `- **[severity]** \`file:line\` — Title. Description.`

Every section must be present. If an agent returned no findings for an area, write 'No findings.' under its heading.

## E. Verify File Was Written

Run: ls -la '<PROJECT_ROOT>/.llmdocs/_review-<TARGET_NAME>-<MODEL_LABEL>.md'

If the file does not exist, write it again. Do not exit without the file."
```

### Step 4: Write Prompt to File

Write the prompt string to a temp file. This avoids shell interpolation issues with large prompts.

```bash
STATE_DIR="$PROJECT_ROOT/.llmdocs/multi_review_state"
mkdir -p "$STATE_DIR"
OPENAI_DIR=$(mktemp -d)
GEMINI_DIR=$(mktemp -d)
CLAUDE_DIR=$(mktemp -d)
cat > /tmp/review-prompt.txt <<'PROMPT_EOF'
<the prompt from step 3>
PROMPT_EOF
```

### Step 5: Launch 3 Separate Background Bash Tasks

Launch each opencode process as its own separate background Bash task. Do NOT launch all 3 in a single shell — child processes get killed when the parent shell exits.

Each is a separate Bash call with `run_in_background`:

**OpenAI:**
```bash
STATE_DIR="<PROJECT_ROOT>/.llmdocs/multi_review_state" && \
opencode run \
  -m openai/gpt-5.3-codex \
  --format json \
  --print-logs \
  --log-level INFO \
  --dir "<OPENAI_DIR>" \
  --title "Review - OpenAI" \
  "$(cat /tmp/review-prompt.txt)" \
  > "$STATE_DIR/openai.ndjson" 2>"$STATE_DIR/openai.log"
```

**Gemini:**
```bash
STATE_DIR="<PROJECT_ROOT>/.llmdocs/multi_review_state" && \
opencode run \
  -m google/gemini-3.1-pro-preview \
  --format json \
  --print-logs \
  --log-level INFO \
  --dir "<GEMINI_DIR>" \
  --title "Review - Gemini" \
  "$(cat /tmp/review-prompt.txt)" \
  > "$STATE_DIR/gemini.ndjson" 2>"$STATE_DIR/gemini.log"
```

**Claude:**
```bash
STATE_DIR="<PROJECT_ROOT>/.llmdocs/multi_review_state" && \
opencode run \
  -m az-anthropic/claude-opus-4-6 \
  --format json \
  --print-logs \
  --log-level INFO \
  --dir "<CLAUDE_DIR>" \
  --title "Review - Claude" \
  "$(cat /tmp/review-prompt.txt)" \
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

### Step 6: Monitor and Wait

Poll each background task until all 3 complete.

**NDJSON progress** — replace `$NDJSON` with the actual path (e.g., `<PROJECT_ROOT>/.llmdocs/multi_review_state/openai.ndjson`):

```bash
# Count completed steps for a model
grep -c '"type":"step_finish"' "$NDJSON" 2>/dev/null || echo 0

# Check if the model finished (last step_finish has reason: "stop")
tail -1 "$NDJSON" 2>/dev/null | jq -r '.part.reason // empty'

# Check for errors in NDJSON events
grep '"type":"error"' "$NDJSON" 2>/dev/null

# Get total cost so far
grep '"type":"step_finish"' "$NDJSON" | jq -s '[.[].part.cost] | add'

# Check tool use activity (subagent spawns, file writes)
grep '"type":"tool_use"' "$NDJSON" | jq -r '.part.tool + " -> " + .part.state.status'
```

**Text logs** — replace `$LOGFILE` with the actual path (e.g., `<PROJECT_ROOT>/.llmdocs/multi_review_state/openai.log`):

```bash
# Check for errors or warnings in text logs
grep -E "^(ERROR|WARN)" "$LOGFILE" 2>/dev/null

# Tail recent log activity
tail -5 "$LOGFILE" 2>/dev/null
```

### Step 7: Report Results

For each model, check if its expected output file exists at `.llmdocs/_review-<TARGET_NAME>-<label>.md`.

Report per model:
- Success/failure (output file present or not)
- Total cost (sum of `cost` from all `step_finish` events)
- Total tokens (from the last `step_finish` event's `tokens.total`)
- Whether any errors occurred

### Step 8: Cleanup

```bash
rm -rf "$STATE_DIR"
rm -f /tmp/review-prompt.txt
```

### Step 9: Synthesize Reviews

Read all successfully produced review files (`.llmdocs/_review-<TARGET_NAME>-*.md`). Compare findings across models and report:

1. **Quorum findings (3/3)** — issues flagged by all three models. List each with the area, severity, and finding.
2. **Quorum findings (2/3)** — issues flagged by two models. List each with the area, severity, which models agreed, and which did not.
3. **Single-model findings** — issues flagged by only one model. List all of them. Note which model raised each.
4. **Conflicting assessments** — areas where models disagree (e.g., one flags a risk, another says it's fine).

Include every finding. Do not skip or summarize away any items.

## Expected Output Files

3 files total, one per model:

- `.llmdocs/_review-<TARGET_NAME>-openai.md`
- `.llmdocs/_review-<TARGET_NAME>-gemini.md`
- `.llmdocs/_review-<TARGET_NAME>-claude.md`

Where `<TARGET_NAME>` is derived from the path's last segment (or `repo` for root).

## NDJSON Log Format Reference

Each opencode process writes NDJSON to `$STATE_DIR/<label>.ndjson`. One JSON object per line. Skip lines that fail to parse (partial writes).

### Event Types

**step_start** - A new LLM turn begins.
```json
{"type":"step_start","timestamp":1773360681884,"sessionID":"ses_...","part":{"type":"step-start","snapshot":"..."}}
```

**text** - Model emitted text output.
```json
{"type":"text","timestamp":1773360682061,"sessionID":"ses_...","part":{"type":"text","text":"some output"}}
```

**tool_use** - Model called a tool. Key fields: `tool` (tool name), `state.status` ("completed" or "error"), `state.input`, `state.output`, `state.metadata.exit` (for bash).
```json
{"type":"tool_use","timestamp":1773360682369,"sessionID":"ses_...","part":{"tool":"bash","state":{"status":"completed","input":{"command":"echo hello"},"output":"hello\n","metadata":{"exit":0}}}}
```

For subagent spawns, `tool` is "task" and `state.output` contains the agent's result text:
```json
{"type":"tool_use","timestamp":...,"part":{"tool":"task","state":{"status":"completed","input":{"description":"...","prompt":"..."},"output":"<task_result>...</task_result>"}}}
```

**step_finish** - An LLM turn completed. Key fields: `reason` ("stop" = done, "tool-calls" = continuing), `cost`, `tokens`.
```json
{"type":"step_finish","timestamp":1773360682446,"sessionID":"ses_...","part":{"reason":"tool-calls","cost":0,"tokens":{"total":13494,"input":2,"output":77,"reasoning":0,"cache":{"read":0,"write":13415}}}}
```

The final `step_finish` with `"reason":"stop"` means the model is done.

**error** - An error occurred at the session level.
```json
{"type":"error","timestamp":...,"sessionID":"ses_...","error":{"name":"UnknownError","data":{"message":"Model not found: ..."}}}
```

### Useful jq Queries

Replace `$NDJSON` with the actual NDJSON file path (e.g., `<PROJECT_ROOT>/.llmdocs/multi_review_state/openai.ndjson`).

```bash
# Is the process done? (last step_finish reason is "stop")
tail -1 "$NDJSON" | jq -r 'select(.type=="step_finish") | .part.reason'

# Total cost
jq -s '[.[] | select(.type=="step_finish") | .part.cost] | add' "$NDJSON"

# Total tokens from final step
tac "$NDJSON" | jq -s 'first(.[] | select(.type=="step_finish")) | .part.tokens.total'

# All tool calls and their status
jq -r 'select(.type=="tool_use") | "\(.part.tool): \(.part.state.status)"' "$NDJSON"

# All errors from NDJSON events
jq -r 'select(.type=="error") | .error.data.message' "$NDJSON"

# Count subagent spawns
jq -r 'select(.type=="tool_use" and .part.tool=="task") | .part.state.status' "$NDJSON" | wc -l
```

Replace `$LOGFILE` with the text log path (e.g., `<PROJECT_ROOT>/.llmdocs/multi_review_state/openai.log`):

```bash
# All errors and warnings from text logs
grep -E "^(ERROR|WARN)" "$LOGFILE"
```

## Rules

- Claude Code is a launcher and synthesizer. All review work happens inside the opencode processes. Claude Code reads the finished review files and synthesizes a cross-model comparison.
- Do NOT perform any review analysis during Steps 1-8. Only analyze review outputs in Step 9.
- Do NOT ask questions during execution. This is non-interactive.
- Launch all 3 processes in parallel. Do not wait for one to finish before starting another.
- Use plain message invocation, not `--command`. The `--command` flag has a known issue with the c7 MCP server.
- Clean up the state directory after reporting results.
- If a model fails, still wait for and report the others.

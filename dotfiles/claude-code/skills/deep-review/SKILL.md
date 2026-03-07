---
name: deep-review
description: 3-phase deep code review pipeline using Joern, mechanical greps, and Ralphy.
user-invokable: true
argument-hint: "<language> [folder]"
---

STARTER_CHARACTER = 🔬

# Deep Review Skill

Run the 3-phase deep code review pipeline against a target directory. Phase 1 uses
Joern for entity extraction and mechanical greps for lead generation. Phase 2b uses
Ralphy with opencode for iterative deep review. Claude Code is a launcher only.

Arguments: $ARGUMENTS

Supported languages and their Joern frontend names:

| Language   | Joern frontend |
|------------|----------------|
| csharp     | csharpsrc      |
| java       | javasrc        |
| python     | pythonsrc      |
| javascript | jssrc          |
| typescript | jssrc          |
| go         | gosrc          |
| c          | newc           |
| cpp        | cppsrc         |

## Procedure

### Step 1: Parse Arguments

Parse $ARGUMENTS as `<language> [folder]`.

The first token is the language (required). The second token is the folder
(optional, defaults to `.` which means the project root).

Validate the language against the table above. If the language is not
recognized, print the supported languages and abort.

```
LANGUAGE = first token of $ARGUMENTS
JOERN_FRONTEND = lookup from table above
TARGET_PATH = second token of $ARGUMENTS (default: .)
PROJECT_ROOT = $(git rev-parse --show-toplevel)
TARGET_ABS = $PROJECT_ROOT/$TARGET_PATH
TARGET_NAME = basename of TARGET_PATH (use repo name if TARGET_PATH is .)
SKILL_DIR = ~/.claude/skills/deep-review
```

If LANGUAGE is empty, print usage and abort:
`Usage: /deep-review <language> [folder]`

Validate the target directory exists. Abort if not.

### Step 2: Preflight Check

```bash
source "$PROJECT_ROOT/.envrc" 2>/dev/null || true
bash "$SKILL_DIR/preflight.sh" "$TARGET_ABS" "$JOERN_FRONTEND"
```

If preflight exits non-zero, report the failures and stop. Do not proceed to Phase 1.

### Step 3: Run Phase 1

```bash
bash "$SKILL_DIR/phase1.sh" "$TARGET_ABS" "$TARGET_NAME" "$PROJECT_ROOT" "$SKILL_DIR" "$JOERN_FRONTEND"
```

Phase 1 runs deterministically with no AI tokens. It produces:
- `.codereview/phase1/cpg.bin` - Joern CPG
- `.codereview/phase1/entities.jsonl` - extracted entities
- `.codereview/phase1/callgraph.csv` - call graph edges
- `.codereview/phase1/inheritance.csv` - inheritance/interface edges
- `.codereview/phase1/entity-summary.txt` - counts
- `.codereview/phase1/grep-*.txt` - grep hit files (7 focus areas)
- `.codereview/phase1/worklist.json` - ranked worklist
- `.codereview/phase2b-workdir/CLAUDE.md` - review protocol
- `.codereview/phase2b-workdir/entity-reference.md` - entity reference table
- `.codereview/phase2b-workdir/PRD.md` - checkboxes for Ralphy
- `/tmp/repomix-$TARGET_NAME.xml` - packed codebase

Monitor output. If phase1.sh exits non-zero, report the error and stop.

### Step 4: Verify Phase 1 Outputs

Run these verification checks and report results:

```bash
cat "$PROJECT_ROOT/.codereview/phase1/entity-summary.txt"
wc -l "$PROJECT_ROOT/.codereview/phase1/callgraph.csv"
wc -l "$PROJECT_ROOT/.codereview/phase1/grep-"*.txt
jq 'length' "$PROJECT_ROOT/.codereview/phase1/worklist.json"
grep -c '^### ' "$PROJECT_ROOT/.codereview/phase2b-workdir/CLAUDE.md"
grep -c '^\- \[ \]' "$PROJECT_ROOT/.codereview/phase2b-workdir/PRD.md"
ls -lh "/tmp/repomix-$TARGET_NAME.xml"
```

Report a summary table of these counts. If any critical file is missing (worklist.json,
CLAUDE.md, PRD.md, repomix), stop and report the error.

### Step 5: Run Phase 2b (Ralphy)

Launch Ralphy in the phase2b working directory:

```bash
cd "$PROJECT_ROOT/.codereview/phase2b-workdir" && ralphy --opencode \
  --model az-anthropic/claude-opus-4-6 \
  --no-commit --max-retries 2
```

Run this as a foreground process. Ralphy iterates through PRD.md checkboxes. Each
checkbox becomes one opencode invocation with CLAUDE.md as project context. The
review agent writes findings to `$PROJECT_ROOT/.llmdocs/_deep-review-<focus>.md`.

This step uses AI tokens and may run for several minutes.

### Step 6: Report Results

After Ralphy completes, report:

```bash
ls -la "$PROJECT_ROOT/.llmdocs/_deep-review-"*.md
wc -l "$PROJECT_ROOT/.llmdocs/_deep-review-"*.md
grep -c '^\- \[x\]' "$PROJECT_ROOT/.codereview/phase2b-workdir/PRD.md"
```

List the review files created, their line counts, and how many PRD checkboxes
were completed.

## Rules

- Claude Code is ONLY a launcher. All review work happens inside Ralphy/opencode.
- Do NOT perform any review analysis directly.
- Do NOT modify source code.
- Do NOT ask questions during execution. This is non-interactive.
- If Phase 1 fails, stop. Do not proceed to Phase 2b with incomplete inputs.
- If Ralphy fails, report what completed (checked boxes in PRD.md) and what remains.

# Deep Code Review Pipeline Architecture

3-phase pipeline for dependency-aware code review of very large codebases. Uses
Joern for entity extraction from the Code Property Graph, mechanical greps for
lead generation, union-find clustering on the call graph, and Ralphy/opencode
for iterative deep review.

## Usage

```text
/deep-review <language> [folder]
```

Language is required. Folder defaults to `.` (project root).

| Language   | Joern frontend |
| ---------- | -------------- |
| csharp     | csharpsrc      |
| java       | javasrc        |
| python     | pythonsrc      |
| javascript | jssrc          |
| typescript | jssrc          |
| go         | gosrc          |
| c          | newc           |
| cpp        | cppsrc         |

Examples:

```text
/deep-review java src/main/java/com/example/auth
/deep-review python services/billing
/deep-review csharp src/Core/Security
/deep-review go .
```

## Context Injection

Ralphy injects `CLAUDE.md` into every prompt as project context. The model
does not read external files referenced in PRD.md preamble text.

- **CLAUDE.md** = review protocol, output format, file navigation, tracing rules
- **PRD.md** = worklist of entity-trace tasks as checkboxes
- **Ralphy** = loop runner that feeds tasks to the engine one at a time

## Pipeline

```text
Phase 1: Context generation (deterministic, no AI tokens)
  joern-parse + extract-cpg.sc -> entities, callgraph, inheritance
  7x grep passes              -> grep hits per focus area
  build-worklist.sh           -> union-find clustering, ranked worklist
  build-claude-md.sh          -> review protocol + entity reference (HOW)
  build-prd.sh                -> clustered checkbox worklist (WHAT)
  repomix                     -> packed codebase snapshot

Phase 2a: Shallow review (3 models, existing /code-review skill)
  3 models x 8 areas via opencode run
  Surface-level findings, fast and cheap
  Output: _review-repo-<model>.md (3 files)
  [NOT YET INTEGRATED]

Phase 2b: Deep review (3 models x 7 focus areas via Ralphy)
  Each model runs full PRD.md independently
  CLAUDE.md injected as project context per invocation
  Each task = one cluster trace through a focus area lens
  Output: _deep-review-<focus>-<model>.md (21 files)

Output: 24 review files (3 shallow + 21 deep), no rollup
  Dedup key (file, line, focus_area) available if cross-referencing needed
```

## File Layout

```text
.claude/skills/deep-review/
  README.md             Architecture and prerequisites (this file)
  SKILL.md              Skill definition (/deep-review)
  extract-cpg.sc        Joern Scala script (CPG queries)
  preflight.sh          Prerequisite checker
  phase1.sh             Master Phase 1 orchestrator
  build-worklist.sh     Entity-grep cross-ref + union-find clustering
  build-claude-md.sh    Review protocol + entity reference table
  build-prd.sh          Worklist -> PRD.md checkboxes
  grep-patterns/        Static grep pattern files (universal.txt + per-language)

.codereview/                   Runtime working directory (not checked in)
  phase1/
    cpg.bin                    Joern Code Property Graph
    entities.jsonl             Classes + methods with file:line
    callgraph.csv              caller_class|caller_method|callee_class|callee_method|file|line
    inheritance.csv            child|parent
    entity-summary.txt         Counts by kind
    grep-<focus>.txt           Grep hits per focus area (7 files)
    worklist.json              Ranked, clustered worklist
  phase2b-workdir/
    CLAUDE.md                  Review protocol + entity reference (injected by Ralphy)
    PRD.md                     Checkbox worklist (consumed by Ralphy)
.llmdocs/                                Final review output (persistent)
  _review-repo-<model>.md                 Phase 2a shallow (3 files)
  _deep-review-<focus>-<model>.md         Phase 2b deep (7 focus x 3 models = 21 files)

/tmp/repomix-<TARGET_NAME>.xml Packed codebase snapshot
```

## Focus Areas

7 universal focus areas, each with grep patterns that work across any language:

| Focus Area       | What It Looks For                                                       |
| ---------------- | ----------------------------------------------------------------------- |
| auth-flow        | Authentication, authorization, session, token, credential handling      |
| data-access      | SQL queries, parameterization, cursors, connection management           |
| crypto           | Encryption, hashing, serialization, key management                      |
| error-handling   | Exception handling patterns, error swallowing, propagation              |
| config-security  | Debug flags, insecure defaults, connection strings, hardcoded addresses |
| dependency-arch  | Injection, factories, service locators, singletons, coupling patterns   |
| codebase-hygiene | TODOs, FIXMEs, deprecated code, stubs, workarounds                      |

### Focus Area Key Questions

| Focus Area       | Key Questions                                                                                                                                        |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| auth-flow        | How does a user authenticate? What happens to credentials end-to-end? How are sessions created and validated? What's stored in session/cookie/token? |
| data-access      | Where does user input reach a query? Are queries parameterized? How are connections managed? Are there transaction boundaries?                       |
| crypto           | What algorithms are used? Where are keys stored? Is cert validation ever disabled? Are there weak or obsolete crypto paths?                          |
| error-handling   | What gets caught and swallowed? What leaks to end users? Is there a consistent error strategy or is it ad-hoc?                                       |
| config-security  | What security-relevant settings exist? Do they differ across environments? Are secrets committed or environment-injected?                            |
| dependency-arch  | How are dependencies resolved (DI, service locator, static, global)? Where are the tight coupling points? Circular dependencies?                     |
| codebase-hygiene | What's dead? What's duplicated? What's in the wrong architectural layer? How much unresolved TODO/FIXME/HACK debt?                                   |

### Grep Pattern Files

Patterns are stored as static files in `grep-patterns/` within the skill
directory. Format is one `<focus>:<regex>` per line. Phase 1 loads
`universal.txt` first, then the language-specific file if it exists.

```text
.claude/skills/deep-review/grep-patterns/
  universal.txt       Always loaded (language-agnostic patterns)
  csharpsrc.txt       Loaded when language=csharp
  javasrc.txt         Loaded when language=java
  pythonsrc.txt       Loaded when language=python
  ...                 Named by Joern frontend, added as needed
```

Language-specific files are optional. The universal file alone produces a
usable worklist.

## Ranking Metrics

Each worklist entity is enriched with graph metrics from the CPG:

- **Fan-in** (callers): how many other methods call this one. High fan-in =
  high blast radius if there's a defect.
- **Fan-out** (callees): how many methods this one calls. High fan-out =
  orchestration point, potential error propagation.
- **Boundary flag**: entity is called from outside its module/namespace.
  Boundary entities are the attack surface.
- **Inheritance depth**: deep hierarchies = harder to reason about behavior.

Rank formula: `grep_hit_count * fan_in_weight`. Entities with both grep hits
(they match anti-patterns) and high fan-in (many callers would be affected)
surface first.

## Clustering Algorithm

Union-find on the call graph subgraph induced by worklist entities within
each focus area. Two entities in the same focus area that share a call edge
(directly or transitively) become one cluster. Singletons remain as
individual tasks.

Reduces task count by grouping related entities into single review units.

## Phase 2b: Operational Details

Each `(focus, model)` pair is an independent opencode subagent. All 21
(7 focus x 3 models) can run concurrently. Each receives the same Phase 1
outputs and writes to its own file (`_deep-review-<focus>-<model>.md`).
No shared state, no write conflicts.

Each subagent gets:

- Filesystem access to the target directory
- CLAUDE.md (review protocol + entity reference table with file:line)
- Its focus area's tasks from PRD.md

## Dedup Key

All reviewers operate on the same Phase 1 base data. Every entity in
`entities.jsonl` has a deterministic `file` and `line` from the CPG. The
review protocol instructs reviewers to cite `file:line` in findings.

The natural dedup key is `(file, line, focus_area)` — stable across models
and phases. No rollup is performed; the 24 review files are the deliverables.
The key is available for ad-hoc cross-referencing if needed.

## Not Yet Built

| Item                           | Notes                                                               |
| ------------------------------ | ------------------------------------------------------------------- |
| Phase 2a integration           | `/code-review` skill exists separately. Need orchestration wrapper. |
| Multi-model Phase 2b           | Run 3 Ralphy instances (Claude/OpenAI/Gemini) against same PRD.     |
| Parallel Ralphy by focus       | Split PRD into per-focus files, run Ralphy instances in parallel.   |
| Tier 2 language-specific greps | Framework-specific pattern files per Joern frontend.                |
| Discovered-entities pass       | Read "Discovered Entities" from review docs, generate PRD-pass2.md. |
| Full-codebase scale            | Bash entity-grep matching is O(n\*m), needs awk/python rewrite.     |

## Prerequisites

### Runtime

| Tool     | Version tested | Purpose                            | Source                                      |
| -------- | -------------- | ---------------------------------- | ------------------------------------------- |
| bash     | 5.x            | Script execution                   | Built-in or via package manager             |
| java     | 11+            | Required by Joern (JVM)            | <https://openjdk.org>                       |
| joern    | 4.0.490        | CPG entity extraction + call graph | <https://joern.io>                          |
| jq       | 1.7+           | JSON processing in shell scripts   | <https://jqlang.github.io/jq/>              |
| awk      | POSIX          | Union-find clustering              | Built-in                                    |
| grep     | POSIX          | Focus area lead generation         | Built-in                                    |
| node     | 18+            | Required by ralphy, opencode       | <https://nodejs.org>                        |
| repomix  | latest         | Codebase packing                   | <https://github.com/yamadashy/repomix>      |
| ralphy   | latest         | Task iteration loop for Phase 2b   | <https://github.com/michaelshimeles/ralphy> |
| opencode | latest         | AI engine (called by Ralphy)       | <https://github.com/sst/opencode>           |

### Java (required by Joern)

Joern runs on the JVM. It does not bundle a JDK — a separate Java 11+ install
is required. `java` must be on PATH and resolve to a working JVM. Run
`java -version` to verify.

### AWS credentials (required for Bedrock models)

opencode uses Amazon Bedrock and Azure Anthropic endpoints. AWS credentials
must be valid before running the pipeline. Verify with:

```bash
aws sts get-caller-identity
```

Configure AWS SSO or static credentials per your organization's process.

### Model Names

| Context              | Model string                                         |
| -------------------- | ---------------------------------------------------- |
| opencode default     | `amazon-bedrock/global.anthropic.claude-opus-4-6-v1` |
| opencode small_model | `amazon-bedrock/global.anthropic.claude-sonnet-4-6`  |
| ralphy `--model`     | `az-anthropic/claude-opus-4-6`                       |

### Claude Code

Phase 2b invokes opencode via Ralphy, not Claude Code directly. However, the
`/deep-review` skill itself is a Claude Code skill and requires Claude Code
to orchestrate the pipeline.

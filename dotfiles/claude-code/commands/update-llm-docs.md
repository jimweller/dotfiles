---
description: Update project documentation (CLAUDE.md + .llmdocs/). Use after significant work to keep docs in sync.
disable-model-invocation: true
argument-hint: "[docs|all]"
---

STARTER_CHARACTER = ✏️


# Update Project Documentation

Two responsibilities:
1. **CLAUDE.md** — concise project overview (always loaded)
2. **.llmdocs/** — detailed per-concept docs (loaded on demand)

---

## 1. CLAUDE.md — The Map

### Gather Context

- Read current `CLAUDE.md` (if exists)
- Explore codebase: directories, config files, key modules
- Review conversation history to identify what changed this session

### Write/Update CLAUDE.md

Target: **under 500 lines**. Every line must earn its place.

```markdown
# <Project Name>

<1-2 line purpose>

## Stack
<bullet list: language, frameworks, key deps>

## Architecture
<key dirs and what they contain>

## Commands
<build, test, lint, deploy — commands only>

## Conventions
<style, naming, patterns — only what prevents mistakes>

## Key Concepts
<domain terms, business logic Claude must know>

## Docs
Detailed docs in `.llmdocs/`:
- @.llmdocs/architecture.md — <1-line description>
- @.llmdocs/data-model.md — <1-line description>

```

### CLAUDE.md Rules

- NO verbose explanations — Claude infers
- NO duplicating .llmdocs/ content — just reference with short description
- The `## Docs` section MUST list all non-ignored .llmdocs/ files with a 1-line description each
- Preserve existing custom instructions (git workflow, env vars, etc.)
- Ask before removing any existing content
- Use `@.llmdocs/filename.md` import if a doc should always be loaded

---

## 2. .llmdocs/ — The Territory

### Process

1. **Assess**: review what was done this session (conversation history, git diff)
2. **Identify**: determine which existing docs are affected, or if a new doc is needed
3. **Propose**: tell the user which docs you plan to update/create and what changes
4. **Validate**: get user approval before writing
5. **Update CLAUDE.md**: ensure the `## Docs` section lists any new doc files

If nothing changed that warrants doc updates, say so and move on.

### Location

Use the path specified in existing CLAUDE.md, or default `.llmdocs/` at project root.

### Structure

Flat, 1 file per concept. The first 5 files are **required** and must always exist. Additional concept files are created as needed.

```
.llmdocs/
  architecture.md    # Components, interactions, data flow (required)
  api.md             # Endpoints, request/response, authentication, authorization (required)
  data-model.md      # Schema, models, relationships (required)
  deployment.md      # Deploy process, environments (required)
  ops.md             # Maintenance, operations, runbooks (required)
  <concept>.md       # Domain-specific as needed
  _*.md              # ignored. do not read, update, or reference
```

### Ignored Files

Never read, update, list, or reference files in `.llmdocs/` that are prefixed with `_` (e.g., `_ralph.md`, `_notes.md`). These files are managed outside this command. Do not include them in the `## Docs` section of CLAUDE.md.

### Doc File Format

```markdown
# <Concept>

<1-line purpose>

## <Section>
<content: headers, tables, code blocks — no prose paragraphs>
```

### .llmdocs/ Rules

- Max 500 lines per file — split if larger
- Include file paths with line refs where useful (`src/auth/login.ts:42`)
- Update existing docs incrementally, don't rewrite from scratch
- If a doc is accurate and unaffected by recent changes, don't touch it
- Accuracy over coverage: only document what's verifiable from code

---

## 3. Summary Output

After running, output:
- Files created/modified
- CLAUDE.md changes (sections added/updated/removed)
- Docs updated/created (or "no doc changes needed")

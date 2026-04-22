---
name: familiarize
description: Orient in a new or unfamiliar repo using Serena LSP symbol analysis with bash fallback.
argument-hint: "[optional: subdirectory to focus on]"
disable-model-invocation: true
---

<!-- markdownlint-disable-file MD041 -->

STARTER_CHARACTER = 🗺️

# Familiarize

No source code writes. No agents. List files and symbols read when done.

$ARGUMENTS

---

## Step 1: Establish Scan Root

```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
```

If `$ARGUMENTS` is provided, treat it as a subdirectory: `SCAN_ROOT=$PROJECT_ROOT/$ARGUMENTS`. If the path does not exist, report it and stop.

If `$ARGUMENTS` is empty, `SCAN_ROOT=$PROJECT_ROOT`.

State the scan root before proceeding.

---

## Step 2: Serena Setup

### 2a. Onboarding check

Call `mcp__serena__check_onboarding_performed`.

- If the tool is not callable, set `SERENA=false` and skip to Step 3.
- If onboarding is already complete, set `SERENA=true`.
- If onboarding is not complete, run `mcp__serena__onboarding` and follow its returned instructions to explore the project and write memory files.
- If any Serena call errors, set `SERENA=false` and continue.

After onboarding completes or is skipped, proceed immediately to Step 2b. Do not continue exploring or writing memories beyond what the onboarding instructions request.

### 2b. Read existing memories

If `SERENA=true`, call `mcp__serena__list_memories`. If memories exist, read each one with `mcp__serena__read_memory`. These provide prior context about the project.

State whether Serena is active and how many memories were loaded before proceeding.

---

## Step 3: Context Docs

### 3a. CLAUDE.md files

Find all `CLAUDE.md` files under `SCAN_ROOT` (exclude `.git/` paths). Read each one.

```bash
find "$SCAN_ROOT" -name "CLAUDE.md" -not -path "*/.git/*" -not -path "*/node_modules/*"
```

### 3b. .llmdocs/ directories

Find all `.llmdocs/` directories under `SCAN_ROOT`. For each, read every `.md` file.

```bash
find "$SCAN_ROOT" -type d -name ".llmdocs" -not -path "*/.git/*"
```

Then for each directory found:

```bash
ls "$LLMDOCS_DIR"/*.md
```

Read each matching file.

Skip silently if not found.

### 3c. Recent commits

```bash
git log --oneline -20
```

---

## Step 4: Repo Metadata

Check for and read each of these files if they exist at `SCAN_ROOT`. Skip any that do not exist without comment.

### Config files

- `.envrc`
- `.env.example`
- `.gitignore`
- `.gitattributes`

### Package manifests

- `package.json`
- `pyproject.toml`
- `Cargo.toml`
- `go.mod`
- `Gemfile`
- `requirements.txt`
- `pom.xml`
- `build.gradle`

### Build and task configs

- `Makefile`
- `Taskfile.yml`
- `justfile`
- `Rakefile`

### Container

- `Dockerfile` (and variants like `Dockerfile.*`)
- `docker-compose*.yml`

### IaC (list filenames only, do not read contents)

- `terraform/*.tf`
- `serverless.yml`
- `sam-template.yaml`

### CI/CD (list filenames only, do not read contents)

- `.github/workflows/*.yml`
- `.gitlab-ci.yml`
- `Jenkinsfile`
- `.circleci/config.yml`

### Documentation

- `README.md` at scan root

---

## Step 5: Code Structure

### 5a. Directory tree

Depth 3, excluding noise directories:

```bash
find "$SCAN_ROOT" -maxdepth 3 \
  -not -path "*/.git/*" \
  -not -path "*/node_modules/*" \
  -not -path "*/__pycache__/*" \
  -not -path "*/vendor/*" \
  -not -path "*/.terraform/*" \
  -not -path "*/.venv/*" \
  -not -path "*/venv/*" \
  -not -path "*/dist/*" \
  -not -path "*/build/*" \
  -not -path "*/.next/*" \
  -not -path "*/target/*" \
  | sort
```

### 5b. Entry point symbols

Identify entry point files under `SCAN_ROOT` by filename pattern:

- `main.*`, `index.*`, `app.*`, `cli.*`
- `__main__.py`
- `cmd/*/main.go`
- `src/lib.rs`, `src/main.rs`
- `server.*`, `handler.*`

Collect up to 5 matches. Prefer files closer to the scan root.

If `SERENA=true`: run `mcp__serena__get_symbols_overview` with `depth: 1` on each match. This returns top-level symbols (classes, functions, interfaces) and their immediate children (methods, attributes) without reading file contents. If a file returns symbols, record them and skip the bash fallback for that file.

If `SERENA=false` or Serena returned empty/error for a file: read the first 50 lines of that file.

### 5c. Architectural symbol search (Serena only)

Skip this step if `SERENA=false`.

Use `mcp__serena__find_symbol` to locate common architectural symbols. Scope each search to `SCAN_ROOT` via the `relative_path` parameter. Use `include_body: false` and `depth: 1`.

Search for these `name_path_pattern` values (skip any that return no results):

- `main`
- `app`
- `server`
- `router`
- `handler`
- `config`
- `middleware`
- `schema`
- `model`

Cap at 10 total `find_symbol` calls. Stop early if the architectural shape is clear.

For the 2-3 most connected symbols found (symbols that appear in multiple files or have many children), optionally call `mcp__serena__find_referencing_symbols` to map who calls them. This tool requires both `name_path` (e.g., `MyClass/my_method`) and `relative_path` (the file where the symbol is defined) from the `find_symbol` results. Cap at 3 reference lookups.

### 5d. Source file symbol mapping

Identify source directories from the directory tree in 5a (directories containing source files, not config/docs/tests).

If `SERENA=true`: run `mcp__serena__get_symbols_overview` with `depth: 1` on up to 3 representative source files per directory. Record class names, function names, and interface names. If a file returns no symbols (unsupported language, error), fall through to bash for that file.

If `SERENA=false` or Serena returned nothing for a file: read the first 50 lines.

Skip in both paths:

- Test files (`*_test.*`, `*.test.*`, `*.spec.*`, `test_*`)
- Generated files (`*.min.js`, `*_pb.go`, `*.generated.*`, `*.g.dart`)
- Lock files (`package-lock.json`, `yarn.lock`, `poetry.lock`, `Cargo.lock`)

---

## Step 6: Report

Output two sections:

### Files and symbols read

List all files read and symbols discovered, grouped by step. For Serena results, list the file path and a count summary (e.g., "3 classes, 12 functions, 2 interfaces"). For bash fallback files, list filenames only.

### Overview

A concise summary of the project based on everything read. Cover:

- What the project does
- Tech stack and key dependencies
- How to build it (build system, compile steps, dependency install)
- How to run or install it (entry points, startup commands, deploy method)
- How to test it (test framework, test commands, test location)
- How the code is organized (key directories and their roles)
- Public API surface and key abstractions (classes, interfaces, exported functions)
- Module relationships and dependency flow (if Serena reference lookups revealed them)
- Conventions or patterns observed in the code
- Anything notable, missing, or unclear

5-7 paragraphs of prose. No bullets or headings in overview.

After the report, await instructions.

---
name: familiarize
description: Orient in a new or unfamiliar repo by reading docs, config, and code structure.
argument-hint: "[optional: subdirectory to focus on]"
disable-model-invocation: true
---

<!-- markdownlint-disable-file MD041 -->

STARTER_CHARACTER = 🗺️

# Familiarize

Read-only. No writes. No agents. List files read when done.

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

## Step 2: Context Docs

### 2a. CLAUDE.md files

Find all `CLAUDE.md` files under `SCAN_ROOT` (exclude `.git/` paths). Read each one.

```bash
find "$SCAN_ROOT" -name "CLAUDE.md" -not -path "*/.git/*" -not -path "*/node_modules/*"
```

### 2b. .llmdocs/ directories

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

### 2c. Recent commits

```bash
git log --oneline -20
```

---

## Step 3: Repo Metadata

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

## Step 4: Code Structure

### 4a. Directory tree

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

### 4b. Entry points

Search for these filename patterns under `SCAN_ROOT`:

- `main.*`, `index.*`, `app.*`, `cli.*`
- `__main__.py`
- `cmd/*/main.go`
- `src/lib.rs`, `src/main.rs`
- `server.*`, `handler.*`

Read the first 50 lines of up to 5 matches. Prefer files closer to the scan root.

### 4c. Pattern sampling

For each source directory identified (directories containing source files, not config), read the first 50 lines of up to 3 representative files per directory.

Skip:

- Test files (`*_test.*`, `*.test.*`, `*.spec.*`, `test_*`)
- Generated files (`*.min.js`, `*_pb.go`, `*.generated.*`, `*.g.dart`)
- Lock files (`package-lock.json`, `yarn.lock`, `poetry.lock`, `Cargo.lock`)

---

## Step 5: Report

Output two sections:

### Files read

List all files that were read (filenames only, grouped by step).

### Overview

A concise summary of the project based on everything read. Cover:

- What the project does
- Tech stack and key dependencies
- How to build it (build system, compile steps, dependency install)
- How to run or install it (entry points, startup commands, deploy method)
- How to test it (test framework, test commands, test location)
- How the code is organized (key directories and their roles)
- Conventions or patterns observed in the code
- Anything notable, missing, or unclear

5-7 paragraphs of prose. No bullets or headings in overview.

After the report, await instructions.

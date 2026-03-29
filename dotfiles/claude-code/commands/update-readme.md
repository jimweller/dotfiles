---
description: Write documentation based on conversation history and folder contents
context: fork
---

STARTER_CHARACTER = 📓

# Documentation Creation

Write markdown content based on the current conversation context and folder contents.

README is current state specification for a human user, not a changelog or decision log or historical record.

## Claude Skills

- use the /md-syntax skill for markdown rules and syntax
- use the /md-style skill for authoring conventions and writing style
- After writing, use /md-lint on the file to format and lint

## Scope

Find all README.md files in the project and update each.
Folder contents are at the README's level and below (siblings and subfolders), never above (parents).
Pay attention to subfolder layers, scope and bounded contexts. Do not leak
concepts between documents at different layers. Each README covers its own
directory level and below, never parent concerns.

$ARGUMENTS

## Gather Diff

Before writing each README, compute what changed since it was last touched.
Use the target file's directory to scope the diff:

```bash
TARGET_DIR=$(dirname <target-readme-path>)
BASELINE=$(git log -1 --format=%H -- <target-readme-path>)
git diff ${BASELINE}..HEAD --stat -- "$TARGET_DIR"
git log --oneline ${BASELINE}..HEAD -- "$TARGET_DIR"
```

Use this diff to identify what sections need updating. Verify code against docs and docs against code.

## README.md Outline

Example document structure for README.md.

```markdown
# Title

Brief overview. No more than five sentencies.

<!-- OPTIONAL IMAGE OR VIDEO HIGHLIGHT -->
<img src="somedemo.png" alt="Some Demo" width="800"/>

## Architecture

High level components and purpose

- Component - purpose
- Component - purpose

## Prerequisites

- Prerequisite - description and reason (accounts, keys, credentials, tools, runtimes, CLIs)

## Project Structure

Show folder structure. Don't include files.

\`\`\`text
davit/
├── src/
│   ├── davit-api/              # Go API server (k8s client) - see src/davit-api/README.md
│   ├── davit-ui/               # Go web UI server - see src/davit-ui/README.md
│   ├── davit-dinghy/           # Alpine dinghy container - see src/davit-dinghy/README.md
│   └── macos-proto-handler/    # macOS VSCode integration - see src/macos-proto-handler/README.md
├── scripts/                    # Build and deployment scripts
└── tests/                      # Test suites
\`\`\`

## Installation

\`\`\`bash
# install manifest
kubectl apply manifest.yaml
\`\`\`

## Usage

\`\`\`bash
# Build all components
make all

# Or build individually
make build-api
make build-dinghy
\`\`\`

## Testing (optional if tests present)

\`\`\`bash
# Run all tests (placeholder)
make test

# Run specific test suites
make test-api
make test-pod
make test-integration
\`\`\`

```

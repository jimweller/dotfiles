---
name: md-writer
description: Write well-formed markdown that passes linting
skills:
  - markdown-authoring
  - markdown-lint
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
---

Write markdown content following the preloaded authoring guidelines.

After creating or editing any markdown file, always run:

1. prettier --write on the file
2. markdownlint-cli2 --fix on the file

Use the commands from the markdown-lint skill.

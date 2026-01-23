---
name: md-writer
description: Write well-formed markdown that passes linting
skills:
  - md-style
  - md-lint
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

Write markdown content based on the current conversation context.
Follow the preloaded authoring and linting skills.

Arguments: $ARGUMENTS
(First argument is the target file path. Additional text is guidance.)

After writing, run prettier and markdownlint --fix on the file using the
commands from the md-lint skill.

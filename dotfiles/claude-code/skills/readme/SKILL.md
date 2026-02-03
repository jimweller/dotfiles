---
name: readme
description: Write documentation based on conversation history and folder contents
user-invocable: true
---

STARTER_CHARACTER = 📓

# Documentation Creation

Write markdown content based on the current conversation context and folder contents.


## Claude Skills

- use the /md-syntax skill for markdown rules and syntax
- use the /md-style skill for authoring conventions and writing style
- After writing, use /md-lint on the file to format and lint

Arguments: $ARGUMENTS

- First argument is the target file path. Additional text is guidance.
- If $ARGUMENTS is empty use README.md in the current directory as the file name
- Folder contents are at file argument level and below (siblings and subfolder), never above (parents)

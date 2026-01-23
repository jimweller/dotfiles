---
name: markdown-authoring
description: Guidelines for writing well-formed markdown files that pass linting.
---

# Markdown Authoring Guidelines

Follow these rules when creating or editing markdown files.

## Rules

1. **Always specify language on code blocks** - Use `bash`, `yaml`, `json`, `text`, `hcl`, `go`, etc. Never use bare ` ``` `

2. **No emojis** - Don't use emojis anywhere in markdown files

3. **Use headings, not bold for section titles** - Use proper heading levels (`##`, `###`, etc.) not `**Bold**` on its own line

4. **Unique heading names** - Never create duplicate headings in the same file

5. **One H1 per file** - Only one `# Title` at the top

6. **First line should be H1** - Start files with `# Title`

7. **Run markdown-lint skill before committing** - Use `/fix-markdown` to format and lint

## Examples

### Code Blocks

```markdown
<!-- WRONG -->
` ` `
some output
` ` `

<!-- CORRECT -->
` ` `text
some output
` ` `
```

### Headings vs Bold

```markdown
<!-- WRONG -->
**Status: Not Implemented**

Some description...

<!-- CORRECT - use appropriate heading level -->
### Status

Not Implemented

Some description...

<!-- ALSO CORRECT (inline) -->
Some description (Status: Not Implemented).
```

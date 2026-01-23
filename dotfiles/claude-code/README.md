# Importing MCP definitions

```bash
claude mcp add-json -s user context7 `cat mcp-context7.json | jq -c`
claude mcp add-json -s user googleresearcher `cat mcp-googleresearcher.json | jq -c`
claude mcp add-json -s user repomix `cat mcp-repomix.json | jq -c`
```

## Agents

The `agents/` directory contains specialized agent configurations.

### md-writer

Location: `agents/md-writer.md`

The md-writer agent writes well-formed markdown files following best practices:

- Preloads `markdown-authoring` and `markdown-lint` skills
- Automatically runs `prettier --write` and `markdownlint-cli2 --fix`
  after creating or editing markdown files
- Enforces rules: language on code blocks, unique headings, no emojis

Invoke with: "Use the md-writer agent to..."

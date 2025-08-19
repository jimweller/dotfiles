# Importing MCP definitions

```bash
claude mcp add-json -s user context7 `cat mcp-context7.json | jq -c`
claude mcp add-json -s user googleresearcher `cat mcp-googleresearcher.json | jq -c`
claude mcp add-json -s user repomix `cat mcp-repomix.json | jq -c`
```

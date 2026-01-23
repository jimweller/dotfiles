# MCP Servers

Model Context Protocol (MCP) servers extend Claude's capabilities by providing
tools for external integrations. These servers are configured in `mcps.json`.

## Configured Servers

### googler

Google search and research capabilities powered by a custom MCP server.

- Web search via Google Custom Search API
- Page scraping and content extraction
- Gemini-powered content analysis
- Combined research workflow

Requires: `GOOGLE_SEARCH_API_KEY`, `GOOGLE_SEARCH_ID`, `GOOGLE_GEMINI_API_KEY`

### repomix

Package codebases into consolidated files for AI analysis.

- `pack_codebase` - Package local directories
- `pack_remote_repository` - Package GitHub repos
- `read_repomix_output` - Read packed output
- `grep_repomix_output` - Search packed output

### c7 (Context7)

Fetch up-to-date documentation for programming libraries and frameworks.

- Query library documentation with semantic search
- Get code examples and API references
- Useful when working with libraries released after Claude's training cutoff

Requires: `CONTEXT7_KEY`

### atl (Atlassian)

Jira and Confluence integration.

- Query and update Jira issues
- Search and read Confluence pages
- Project and sprint management

Requires: `JIRA_URL`, `JIRA_USERNAME`, `JIRA_API_TOKEN`, `CONFLUENCE_URL`,
`CONFLUENCE_API_TOKEN`

### github

GitHub Copilot MCP server for repository operations.

Requires: `GITHUB_TOKEN`

### serena

Code understanding and navigation using language server protocols. Provides
semantic code analysis including symbol lookup, references, and definitions.

### ado (Azure DevOps)

Azure DevOps integration for work items and pipelines.

Requires: `AZURE_DEVOPS_EXT_PAT`

## Adding MCP Servers

Use the Claude CLI to add servers from JSON definitions:

```bash
claude mcp add-json -s user <name> "$(cat mcp-<name>.json | jq -c)"
```

Or add directly to `~/.claude.json` under `mcpServers`.

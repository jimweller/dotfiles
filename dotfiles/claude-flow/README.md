# Claude Flow Configuration

CLAUDE.md and MCP tool reference rules for Claude Code with Claude-Flow multi-agent orchestration.

## Architecture

- `CLAUDE.md` - Main configuration: tool execution hierarchy, concurrent execution rules, file organization, SOPs, integration patterns
- `rules/` - Per-tool reference guides loaded via `@rules/<tool>.md`

## Project Structure

```text
claude-flow/
├── CLAUDE.md
└── rules/
    ├── atl.md          # Jira and Confluence MCP tool reference
    ├── claude-flow.md  # Claude-Flow MCP native tool reference (80+ tools)
    ├── context7.md     # Official documentation retrieval patterns
    ├── googler.md      # Web research and analysis workflows
    ├── repomix.md      # Codebase packaging and analysis
    └── test-prompts.md # Test prompts and validation guide
```

## Installation

Symlinked to `~/.claude/` via dotbot. The `CLAUDE.md` file is loaded automatically by Claude Code as project-level instructions when present in the working directory.

## MCP Servers

| Server      | Purpose                                   |
| ----------- | ----------------------------------------- |
| claude-flow | Multi-agent orchestration, memory, swarm  |
| context7    | Official library documentation retrieval  |
| googler     | Web research, scraping, AI analysis       |
| agentdb     | Reinforcement learning, experience replay |
| repomix     | Codebase analysis and packaging           |
| atl         | Jira and Confluence management            |

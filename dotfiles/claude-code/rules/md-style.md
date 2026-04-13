---
paths:
  - "**/README.md"
---

# README Style Guide

Write concise, direct README files for experienced engineers.

## Principles

- **No fluff** - Skip tables of contents, verbose explanations, development history
- **No roadmaps** - Document current state only, not plans or decisions. Readme is an engineering specification. Not a project plan or changelog.
- **No repetition** - Each fact appears once
- **No marketing language** - Avoid "next generation", "production ready", "powerful", "comprehensive" and similar hyperbole
- **Direct voice** - State facts, not opinions
- **No contrasting embellishments** - Avoid like "not just a thing, it's a better thing", "not only a thing, it's something", "more than a"

## Structure Template

```markdown
# Component Name

One-line description of what it does.

## Usage

\`\`\`bash
./install.sh
./uninstall.sh
\`\`\`

## Architecture

| Component | Description |
|-----------|-------------|
| Item 1 | What it is |
| Item 2 | What it is |

## Configuration

Key variables and their purpose. Use tables for structured data.

## Testing

\`\`\`bash
# Essential verification commands only
make test
\`\`\`

## File Structure

\`\`\`text
component/
├── install.sh
├── uninstall.sh
└── manifests/
\`\`\`
```

## Guidelines

### Include

- Purpose (one line)
- Install/uninstall commands
- Key configuration (tables preferred)
- Verification commands
- File structure (if non-obvious)

### Exclude

- Tables of contents
- Prerequisites lists (assume competent audience)
- Verbose troubleshooting guides
- Development decisions/history
- Future plans/roadmaps
- Lengthy explanations of concepts
- Multiple examples of similar things

### Formatting

- Tables for structured data (components, variables, test coverage)
- Code blocks for commands and examples
- Bold for emphasis sparingly
- No emojis unless explicitly requested
- No emdashes

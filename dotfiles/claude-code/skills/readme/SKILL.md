# README Style Guide

Write concise, direct README files for experienced engineers.

## Principles

1. **No fluff** - Skip tables of contents, verbose explanations, development history
2. **No roadmaps** - Document current state only, not plans or decisions. Readme is an engineering specification. Not a project plan or changelog.
3. **No repetition** - Each fact appears once
4. **No marketing language** - Avoid "next generation", "production ready", "powerful", "comprehensive" and similar hyperbole
5. **Direct voice** - State facts, not opinions
6. **No AI slop** - Never use Emojis, glyphs or emdashes
7. **No contrasting embellishments** - Avoid like "not just a thing, it's a better thing", "not only a thing, it's something", "more than a"

## Structure Template

```markdown
# Component Name

One-line description of what it does.

## Usage

\`\`\`bash
./install.sh
./uninstall.sh
\`\`\`

## Components/Architecture

| Component | Description |
|-----------|-------------|
| Item 1 | What it is |
| Item 2 | What it is |

## Configuration

Key variables and their purpose. Use tables for structured data.

## Verification

\`\`\`bash
# Essential verification commands only
kubectl get pods -n namespace
\`\`\`

## File Structure (optional)

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

## Example Transformation

**Before (verbose):**
```markdown
## Purpose

This module provides comprehensive networking infrastructure including
Virtual Networks, Subnets, Network Security Groups, and NAT Gateways.
The architecture follows Azure best practices for hub-spoke topology...

### Why We Made These Decisions

After evaluating several approaches, we decided to use service endpoints
because they provide a simpler implementation path without requiring...
```

**After (concise):**
```markdown
# Networking Module

Creates VNet, subnets, NSG, NAT Gateway, and service endpoints.

## Architecture

\`\`\`text
VNet (10.x.0.0/22)
├── Main Subnet (10.x.0.0/24) - AKS nodes
└── AGW Subnet (10.x.1.0/24) - Application Gateway
\`\`\`
```

---
name: jc
description: JIRA conventions for DEVX project work tracking.
---

# JC - JIRA Conventions for DEVX

Apply these conventions when handling JIRA requests for the DEVX project.

## Defaults

| Field | Value |
|-------|-------|
| Project | DEVX |
| Issue Type | Task |
| Labels | Platform |
| Assignee on transition | jim.weller@mcg.com |

## Issue Key Recognition

Accept flexible formats:
- `DEVX-209` (full key)
- `devx-209` (lowercase)
- `DEVX209` (uppercase, no hyphen)
- `devx209` (lowercase, no hyphen)
- `209` (number only, prefix with DEVX-)

## Description Format

Use DEVX panel template for new issues:

```text
{panel:bgColor=#deebff}
h3. CONTEXT
<narrative: background, expected outcomes, why this matters>
{panel}

h3. THE WORK HERE
<bullet points of tasks to complete>

h3. DETAILS
<optional: technical information supporting the work - config values, Azure resources, IP addresses, command lines, data, etc.>
```

## Operations

### Create

- Draft summary from conversation if not provided
- Build CONTEXT from conversation discussion
- Extract work items from conversation
- Apply labels: Platform
- Output the issue URL after creation: `https://jira.mcg.com/browse/DEVX-XXX`
- Parent field syntax: `"parent": "DEVX-XXX"` (string, not object)

### Read

- Display: Key, Summary, Status, Priority, Description, Comments

### Transition

- Auto-assign to jim.weller@mcg.com on any status change
- Use `mcp__atl__jira_update_issue` after transition to set assignee if transition fields don't work
- Common statuses: Backlog, To Do, In Progress, Done, Blocked

### Close

- Transition to Done
- Auto-assign to jim.weller@mcg.com

### Comment

- If no comment text provided, summarize current conversation

### List

- JQL: `project = DEVX AND labels = Claude AND status != Done ORDER BY created DESC`

---
name: jira
description: Jira conventions and operations. Always use when when working with jira issues, tickets, stories, tasks, epics, comments, or attachments.
user-invocable: false
---

STARTER_CHARACTER = 🎟️

# JIRA Conventions

Jira is an issue tracking sytem. Use the atl mcp, jira cli, and jira api with curl according to the directions for the entity and operation.

## Instance

Use environment variables for JIRA configuration:

| Variable         | Description                                         |
| ---------------- | --------------------------------------------------- |
| `JIRA_URL`       | Base URL (e.g., `https://mcghealth.atlassian.net/`) |
| `JIRA_EMAIL`     | User email for authentication                       |
| `JIRA_API_TOKEN` | API token for authentication                        |

- Browse URL: `${JIRA_URL}browse/{KEY}`

## MCP Tool Data Types

When calling tools, use correct data types for parameters:

| Type    | Example                       | Wrong                              |
| ------- | ----------------------------- | ---------------------------------- |
| Integer | `limit=10`                    | `limit="10"`                       |
| String  | `issue_key="DEVX-123"`        | `issue_key=DEVX-123`               |
| Object  | `fields={"summary": "Title"}` | `fields="{\"summary\": \"Title\"}"` |
| Array   | `labels=["bug", "urgent"]`    | `labels="[\"bug\", \"urgent\"]"`   |

Incorrect types cause validation errors like: `'10' is not of type 'integer'`

## Issue Creation Defaults

When creating issues, apply these defaults unless the conversation explicitly specifies otherwise:

| Field             | Default Value                              | Custom Field         |
| ----------------- | ------------------------------------------ | -------------------- |
| Work Type         | `Feature` (Task), `Overhead` (OpsTask) | `customfield_11096`  |
| Story Points      | `0.5`                                      | `customfield_10123`  |
| Engineering Owner | matches assignee                           | `customfield_12165`  |
| Parent            | none                                       |                      |
| Assignee          | none                                       |                      |
| Label             | `Platform`                                 |                      |
| Reporter          | `JIRA_EMAIL` env var value                 |                      |

- **Work Type**: Set via `additional_fields={"customfield_11096": {"value": "Feature"}}`. Default is `Feature` for Task, `Overhead` for OpsTask. Valid values include Feature, Overhead, and others defined in the project.
- **Story Points**: `customfield_10123` ("Story Points") is displayed in the board UI. Always set to `0.5` via `additional_fields={"customfield_10123": 0.5}` unless a different value is specified.
- **Engineering Owner**: Do not set by default. Only set when the issue has an assignee. When set, it must match the assignee. Use `"customfield_12165": {"accountId": "<account_id>"}` in `additional_fields`. On every create or update, check if assignee is present and set Engineering Owner accordingly.
- **Parent**: Do not set a parent unless explicitly provided.
- **Assignee**: Leave unassigned unless someone is explicitly designated to perform the work (e.g., "assign to X", "X will handle this"). The person requesting work, sending an email, or filing a request is the reporter, not the assignee. Being mentioned in the conversation does not imply assignment.
- **Label**: Always include `Platform` in the labels array. Merge with any additional labels requested.
- **Reporter**: Defaults to the current user (`JIRA_EMAIL`). If the work request originates from someone else (e.g., an email author, a requestor), set the reporter to that person. **Reporter cannot be set during creation via `additional_fields`. It is silently ignored.** After creating the issue, immediately call `mcp__atl__jira_update_issue` with `fields={"reporter": "user@example.com"}` to set the reporter. The value must be a plain email string, not an object.

## Issue Key Recognition

`{KEY}` refers to the normalized JIRA issue key in format `PROJ-###` (e.g., `DEVX-209`).

The default jira project is DEVX. DEVX-###.

Accept flexible input formats:

- `PROJ-209` (full key)
- `proj-209` (lowercase)
- `PROJ209` (no hyphen)
- `proj209` (lowercase, no hyphen)
- `209` (number only, requires project context)

Always normalize to uppercase with hyphen: `DEVX-209`

## Writing Standards

- No emojis
- No glyphs
- No emdashes
- Direct, technical language
- Clear imperative sentences

## Formatting Conventions

- Prose is normal paragraphs
- Code and commands use code blocks
- Citations from documentation or other people use block quotes

## MCP ATL Markup Format

**IMPORTANT:** The MCP ATL tools (`mcp__atl__jira_create_issue`, `mcp__atl__jira_update_issue`, `mcp__atl__jira_add_comment`) convert Markdown to Jira wiki format automatically.

### Use Markdown for content

Code blocks with shebangs:
```
#!/bin/bash
set -euo pipefail
```

Nested lists (use indentation):
- Level 1
  - Level 2
    - Level 3

### Wiki markup panels are supported

Panels can wrap markdown content:
```
{panel:bgColor=#deebff}
### Context
Content here uses markdown.
{panel}
```

### Do NOT use wiki markup for content

Passing wiki markup for regular content causes double-conversion bugs:
- `{code}#!/bin/bash{code}` → `#` becomes `h1.`
- `** nested item` → `**` becomes `__`

### Known Limitations

- Jira does not support syntax highlighting in code blocks

## Description Format

Use panel template for new issues (panel is wiki markup, content is markdown):

```
{panel:bgColor=#deebff}
### Context
<narrative: background, expected outcomes, why this matters>
{panel}

### The Work
<bullet points of tasks to complete>

### Details
<optional: technical information - config values, resources, commands, data>
```

## Operations

# Epic

## create

```
mcp__atl__jira_create_issue(
  project_key="PROJ",
  issue_type="Epic",
  summary="Epic title",
  description="{panel:bgColor=#deebff}\n### Context\nBackground and why this matters.\n{panel}\n\n### The Work\n- First task\n- Second task\n\n### Details\nTechnical information."
)
```

## read

```
mcp__atl__jira_get_issue(
  issue_key="PROJ-123"
)
```

## update

```
mcp__atl__jira_update_issue(
  issue_key="PROJ-123",
  fields={
    "summary": "New title",
    "description": "{panel:bgColor=#deebff}\n### Context\nUpdated background.\n{panel}\n\n### The Work\n- Updated tasks\n\n### Details\nUpdated details."
  }
)
```

## cancel

```
mcp__atl__jira_transition_issue(
  issue_key="PROJ-123",
  transition_id="91"
)
```

## list children

```
jira issue list -q "parent = PROJ-123" -p PROJ --plain
```

# Task

## create

Step 1: Create the issue.

```
mcp__atl__jira_create_issue(
  project_key="PROJ",
  issue_type="Task",
  summary="Task title",
  description="{panel:bgColor=#deebff}\n### Context\nBackground and why this matters.\n{panel}\n\n### The Work\n- First task\n- Second task\n\n### Details\nTechnical information.",
  labels=["Platform"],
  additional_fields={"customfield_10123": 0.5, "customfield_11096": {"value": "Feature"}}
)
```

Step 2: If the issue has an assignee, set Engineering Owner to match.

```
mcp__atl__jira_update_issue(
  issue_key="PROJ-456",
  additional_fields={"customfield_12165": {"accountId": "<assignee_account_id>"}}
)
```

Step 3: Set the reporter if different from current user (reporter cannot be set during creation).

```
mcp__atl__jira_update_issue(
  issue_key="PROJ-456",
  fields={"reporter": "requester@example.com"}
)
```

## create with parent

```
mcp__atl__jira_create_issue(
  project="PROJ",
  issue_type="Task",
  summary="Task title",
  description="{panel:bgColor=#deebff}\n### Context\nBackground and why this matters.\n{panel}\n\n### The Work\n- First task\n- Second task\n\n### Details\nTechnical information.",
  additional_fields={"parent": "PROJ-123", "customfield_10123": 0.5, "customfield_11096": {"value": "Feature"}}
)
```

## read

```
mcp__atl__jira_get_issue(
  issue_key="PROJ-456"
)
```

## update

```
mcp__atl__jira_update_issue(
  issue_key="PROJ-456",
  fields={
    "summary": "New title",
    "description": "{panel:bgColor=#deebff}\n### Context\nUpdated background.\n{panel}\n\n### The Work\n- Updated tasks\n\n### Details\nUpdated details."
  }
)
```

## cancel

```
mcp__atl__jira_transition_issue(
  issue_key="PROJ-456",
  transition_id="91"
)
```

## search

```
jira issue list -q "project = PROJ AND status != Done ORDER BY created DESC" -p PROJ --plain
```

# Link

## link to epic

```
mcp__atl__jira_link_to_epic(
  issue_key="PROJ-456",
  epic_key="PROJ-123"
)
```

## create link

```
mcp__atl__jira_create_issue_link(
  inward_issue_key="PROJ-456",
  outward_issue_key="PROJ-789",
  link_type="Blocks"
)
```

Common link types: Blocks, Dependency, Duplicate, Relates, Parent/Child

## get types

```
mcp__atl__jira_get_link_types()
```

## remove

```
mcp__atl__jira_remove_issue_link(
  issue_key="PROJ-456",
  link_id="12345"
)
```

# Assignment

## assign

```
mcp__atl__jira_update_issue(
  issue_key="PROJ-456",
  fields={"assignee": "user@example.com"}
)
```

## unassign

```
mcp__atl__jira_update_issue(
  issue_key="PROJ-456",
  fields={"assignee": null}
)
```

## get user

```
mcp__atl__jira_get_user_profile()
```

# Transition/Move

## get available

```
mcp__atl__jira_get_transitions(
  issue_key="PROJ-456"
)
```

## change status

```
mcp__atl__jira_transition_issue(
  issue_key="PROJ-456",
  transition_id="31"
)
```

**Rule:** When transitioning an issue to Done, always assign it to the current user (from `JIRA_EMAIL`) if unassigned. Use `jira_update_issue` with `fields={"assignee": "user@example.com"}` or `fields={"assignee": null}` to unassign.

# Comment

## add

```
mcp__atl__jira_add_comment(
  issue_key="PROJ-456",
  comment="Comment text here."
)
```

Optional `visibility` parameter restricts comment to a role or group:
```
mcp__atl__jira_add_comment(
  issue_key="PROJ-456",
  comment="Internal note.",
  visibility={"type": "role", "value": "Service Desk Team"}
)
```

## read

```
mcp__atl__jira_get_issue(
  issue_key="PROJ-456",
  fields="summary,comment",
  comment_limit=10
)
```

Note: When `comment_limit > 0`, the comment field is auto-included in the response.

## update

```
mcp__atl__jira_edit_comment(
  issue_key="PROJ-456",
  comment_id="12345",
  comment="Updated comment text."
)
```

## delete

```
curl -X DELETE \
  -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
  "${JIRA_URL}rest/api/2/issue/PROJ-456/comment/12345"
```

# Attachment

## add

```
mcp__atl__jira_update_issue(
  issue_key="PROJ-456",
  fields={},
  attachments="/path/to/file.pdf"
)
```

## read

```
mcp__atl__jira_get_issue(
  issue_key="PROJ-456",
  fields="attachment"
)
```

The attachment ID is in the response at attachments array.

## download

```
mcp__atl__jira_download_attachments(
  issue_key="PROJ-456"
)
```

Returns attachment content as embedded base64 resources.

## delete

```
curl -X DELETE \
  -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
  "${JIRA_URL}rest/api/3/attachment/12345"
```

# Priority

## get

```
mcp__atl__jira_get_issue(
  issue_key="PROJ-456"
)
```

The priority is in the response at priority.name.

## set

```
mcp__atl__jira_update_issue(
  issue_key="PROJ-456",
  fields={"priority": {"name": "High"}}
)
```

Valid values: Highest, High, Medium, Low, Lowest

# Label

## add

First get current labels, then update with the merged list.

```
mcp__atl__jira_get_issue(
  issue_key="PROJ-456"
)
```

```
mcp__atl__jira_update_issue(
  issue_key="PROJ-456",
  fields={"labels": ["existing-label", "new-label"]}
)
```

## remove

First get current labels, then update with the filtered list.

```
mcp__atl__jira_get_issue(
  issue_key="PROJ-456"
)
```

```
mcp__atl__jira_update_issue(
  issue_key="PROJ-456",
  fields={"labels": ["remaining-label"]}
)
```

## list

```
mcp__atl__jira_get_issue(
  issue_key="PROJ-456"
)
```

Labels are in the response at labels array.

# Story Points

Custom field: `customfield_10123` (Story Points, displayed in the board UI)

## set

```
mcp__atl__jira_update_issue(
  issue_key="PROJ-456",
  fields={},
  additional_fields={"customfield_10123": 0.5}
)
```

## get

```
mcp__atl__jira_get_issue(
  issue_key="PROJ-456",
  fields="summary,customfield_10123"
)
```

The value is at customfield_10123 in the response. Common values: 0.5, 1, 2, 3, 5, 8, 13.

# Development Info

## get

```
mcp__atl__jira_get_issue_development_info(
  issue_key="PROJ-456"
)
```

Returns linked branches, commits, and pull requests from connected source control.

# Dates

## get

```
mcp__atl__jira_jira_get_issue_dates(
  issue_key="PROJ-456"
)
```

Returns created, updated, due date, resolution date, and optionally status change history.

# SLA

## get

```
mcp__atl__jira_jira_get_issue_sla(
  issue_key="PROJ-456"
)
```

Returns cycle time, lead time, time in status, and due date compliance metrics.

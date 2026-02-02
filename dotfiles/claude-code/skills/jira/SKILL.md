---
name: jira
description: JIRA conventions and patterns for ticket operations
---

# JIRA Conventions

Apply these conventions when handling JIRA operations. Use the `atl` MCP server for all JIRA API interactions.

## Instance

Use environment variables for JIRA configuration:

| Variable | Description |
|----------|-------------|
| `JIRA_URL` | Base URL (e.g., `https://mcghealth.atlassian.net/`) |
| `JIRA_EMAIL` | User email for authentication |
| `JIRA_API_TOKEN` | API token for authentication |

- Browse URL: `${JIRA_URL}browse/{KEY}`

## Issue Key Recognition

`{KEY}` refers to the normalized JIRA issue key in format `PROJ-###` (e.g., `DEVX-209`).

Accept flexible input formats:

- `PROJ-209` (full key)
- `proj-209` (lowercase)
- `PROJ209` (no hyphen)
- `proj209` (lowercase, no hyphen)
- `209` (number only, requires project context)

Always normalize to uppercase with hyphen: `DEVX-209`

## Description Format

Use panel template for new issues:

{panel:bgColor=#deebff}
h3. CONTEXT
<narrative: background, expected outcomes, why this matters>
{panel}

h3. THE WORK HERE
<bullet points of tasks to complete>

h3. DETAILS
<optional: technical information - config values, resources, commands, data>

## Operations

### Create

- Draft summary from conversation if not provided
- Build CONTEXT from conversation discussion
- Extract work items from conversation
- Output issue URL after creation: `https://mcghealth.atlassian.net/browse/{KEY}`
- Parent field syntax: `"parent": "PROJ-XXX"` (string, not object)

### Attach Plan

**Only attach plans when explicitly requested by the user.** Never attach automatically.

**Rule: Only one `{KEY}-plan.md` attachment per issue.** Always check for existing plan attachment and delete it before attaching a new one.

Workflow:

1. Fetch issue to check for existing plan attachment:
   ```
   mcp__atl__jira_get_issue(issue_key="{KEY}", fields="attachment")
   ```
2. If `{KEY}-plan.md` exists, delete it (see Delete Attachment below)
3. Write plan to temp file: `/tmp/{KEY}-plan.md`
4. Attach using `mcp__atl__jira_update_issue`:
   ```
   mcp__atl__jira_update_issue(
     issue_key="{KEY}",
     fields={},
     attachments="/tmp/{KEY}-plan.md"
   )
   ```

### Delete Attachment

The `atl` MCP server does not support deleting attachments. Use curl with JIRA environment variables.

1. Get attachment ID from issue (in attachment URL or via API)
2. Delete using curl:

```bash
curl -X DELETE \
  -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
  "${JIRA_URL}rest/api/3/attachment/{ATTACHMENT_ID}"
```

- Returns HTTP 204 on success

### Read

Display: Key, Summary, Status, Priority, Assignee, Description, Comments

### Transition

- Common statuses: Backlog, To Do, In Progress, Done, Blocked
- Use `mcp__atl__jira_transition_issue` for status changes
- Fallback to `mcp__atl__jira_update_issue` if transition fields unavailable
- **Auto-assign on transition**: If issue is unassigned, assign to `${JIRA_EMAIL}` when transitioning

### Close

- Transition to Done status

### Comment

- If no comment text provided, summarize current conversation

### List

JQL template:
project = {PROJECT} AND status != Done ORDER BY created DESC

## Writing Standards

- No emojis
- Direct, technical language
- Clear imperative sentences

# JIRA Skill for DEVX Work Tracking

Manage DEVX issues with Claude memory persistence. Supports natural language requests.

Arguments: $ARGUMENTS

## Intent Recognition

Parse $ARGUMENTS naturally. Recognize these intents:

| Intent | Trigger phrases |
|--------|-----------------|
| create | "create", "new issue", "make a ticket", "capture this" |
| read | "read", "get", "show", "fetch", "load" |
| transition | "transition", "move to", "set status", "in progress", "to do" |
| close | "close", "done", "complete", "finish", "resolve" |
| comment | "comment", "add comment", "note" |
| list | "list", "show open", "my issues", "find" |

Extract issue key from arguments (e.g., "DEVX-209", "devx-209", "209" all map to DEVX-209).

## Operation: create

When creating an issue:

1. Extract the summary from arguments (everything after "create"), or if no summary provided, draft a concise summary (under 10 words) based on the main topic of the conversation
2. Analyze the current conversation to build the CONTEXT section:
   - What problem or feature was discussed
   - What outcomes are expected
   - Why this matters
3. Summarize the work items from the conversation
4. Format using the DEVX template below
5. Call `mcp__atl__jira_create_issue` with:
   - `project_key`: "DEVX"
   - `issue_type`: "Task"
   - `summary`: the provided summary
   - `description`: formatted description (see template)
   - `labels`: ["Platform", "Claude"]
6. Report the created issue key

### Description Template

```
{panel:bgColor=#deebff}
*CONTEXT*
<summarize the conversation: background, expected outcomes, why this matters>
{panel}

*The Work*
<bullet points of what needs to be done based on conversation>
```

## Operation: read

When reading an issue:

1. Extract the issue key from arguments (e.g., "DEVX-207")
2. Call `mcp__atl__jira_get_issue` with the key
3. Display the issue in a readable format:
   - Key and Summary
   - Status and Priority
   - Description (preserve formatting)
   - Comments if any
4. Confirm the context is loaded for planning

## Operation: transition

When transitioning an issue:

1. Extract the issue key and target status from arguments
2. Call `mcp__atl__jira_get_transitions` to get available transitions
3. Match target status to transition name (case-insensitive)
4. Call `mcp__atl__jira_transition_issue` with the transition ID and assign to jim.weller@mcg.com:
   - `fields`: {"assignee": {"name": "jim.weller@mcg.com"}}
5. Confirm the transition

Common status targets: Backlog, To Do, In Progress, Done, Blocked, Ready for Review

## Operation: close

When closing an issue:

1. Extract the issue key from arguments
2. Call `mcp__atl__jira_get_transitions` to find the "Done" transition ID
3. Call `mcp__atl__jira_transition_issue` with the transition ID and assign to jim.weller@mcg.com:
   - `fields`: {"assignee": {"name": "jim.weller@mcg.com"}}
4. Confirm the issue is closed

## Operation: comment

When adding a comment:

1. Extract the issue key from arguments
2. Determine comment content:
   - If provided in arguments, use that
   - Otherwise, summarize the current conversation as the comment
3. Call `mcp__atl__jira_add_comment` with the issue key and comment body
4. Confirm the comment was added

## Operation: list

When listing issues:

1. Call `mcp__atl__jira_search` with JQL:
   - `project = DEVX AND labels = Claude AND status != Done ORDER BY created DESC`
2. Display results in a table format:
   - Key | Summary | Status | Created

## Defaults

| Field | Value |
|-------|-------|
| project_key | DEVX |
| issue_type | Task |
| labels | Platform, Claude |

## Examples

Natural language:
```
/jira-claude create a new issue for auth timeout
/jira-claude read devx-209
/jira-claude transition 209 to in progress
/jira-claude add comment to devx-209
/jira-claude close 209
/jira-claude list my open issues
```

Shorthand:
```
/jira-claude create
/jira-claude read 209
/jira-claude close 209
/jira-claude list
```

## Error Handling

- If no arguments provided, show usage help
- If issue key not found, report the error clearly
- If transition fails, show available transitions

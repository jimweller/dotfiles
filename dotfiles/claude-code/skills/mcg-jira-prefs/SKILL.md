---
name: mcg-jira-prefs
description: mcg-atlassian:jira skill j-cli Jira team defaults, custom fields, creation rules. Apply these defaults when working with Jira issues, tickets, epics, stories.
user-invocable: false
---

# Local Jira Configuration

Default project: DEVX

## Creation Defaults

Apply unless the conversation specifies otherwise.

| Field             | Default                                | Custom Field      |
| ----------------- | -------------------------------------- | ----------------- |
| Work Type         | `Feature` (Task), `Overhead` (OpsTask) | customfield_11096 |
| Story Points      | `0.5`                                  | customfield_10123 |
| Engineering Owner | matches assignee (use accountId)       | customfield_12165 |
| Label             | `Platform`                             |                   |
| Reporter          | `JIRA_EMAIL` value                     |                   |

- Work Type: Feature for Task, Overhead for OpsTask
- Story Points: 0.5
- Engineering Owner: set only when assignee exists, must match assignee
- Label: always include Platform, merge with additional labels
- Reporter: defaults to current user. If requester differs, set reporter to them.

## Custom Fields

| Name              | ID                |
| ----------------- | ----------------- |
| Story Points      | customfield_10123 |
| Work Type         | customfield_11096 |
| Engineering Owner | customfield_12165 |

## Assignee Rules

- Leave unassigned unless someone is explicitly designated to do the work
- Requester = reporter, not assignee
- Mentioned in conversation does not imply assignment


## Description Template

    {panel:bgColor=#deebff}
    h3. Context
    <narrative: background, expected outcomes, why this matters>
    {panel}

    h3. The Work
    <bullet points of tasks>

    h3. Details
    <optional: technical info, config values, resources, commands>

All wiki markup. Use `h3.` for headings, `*` for bullets.
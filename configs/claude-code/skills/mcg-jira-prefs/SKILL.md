---
name: mcg-jira-prefs
description: mcg-atlassian:jira skill j-cli Jira team defaults, custom fields, creation rules. Apply these defaults when working with Jira issues, tickets, epics, stories.
user-invocable: false
---

<!-- markdownlint-disable-file MD041 -->

STARTER_CHARACTER = 🎫

# Local Jira Configuration

Default project: DEVX

When the user gives only a number (e.g. `451`), resolve it against the default project: `DEVX-451`.

## Ticket Transitions

Never transition a ticket straight to Done. Transition to In Progress first, then to Done. This applies even when the work is already finished before the ticket is touched.

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

## DevX Team Roster

Current members:

- Matt Grdinic
- Jim.Weller
- nate.curtis
- Nathaniel.Brumbach
- Joe.Clancy
- Cesar.Carrillo

Former members:

- Bart Mielnik

Use the reporter field, not the creator field, to decide whether an issue came from the team or from an outside requester. Team members sometimes file issues on behalf of requesters, which makes creator unreliable.

An issue reported by anyone outside this roster is an inbound service request, not roadmap work.

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

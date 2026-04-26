# ATL MCP - Jira & Confluence Management

**Target:** LLM execution
**Purpose:** Manage Jira issues, sprints, boards, and Confluence pages/spaces
**Last Updated:** 2025-11-15

---

## TOOL INVOCATION

### JIRA ISSUE OPERATIONS

#### jira_get_issue

````text
mcp__atl__jira_get_issue({
  issue_key: string,
  fields?: string,
  expand?: string,
  comment_limit?: number,
  properties?: string,
  update_history?: boolean
})
```text

**Purpose:** Get detailed Jira issue information including Epic links
**Returns:** Full issue object with specified fields

**Parameters:**

- `issue_key` (required): Issue key (e.g., "PROJ-123")
- `fields` (optional): Comma-separated fields or "\*all" (default: essential fields)
- `expand` (optional): Expand fields ("renderedFields", "transitions", "changelog")
- `comment_limit` (optional): Max comments (default: 10, 0 for none)
- `properties` (optional): Issue properties to return
- `update_history` (optional): Update view history (default: true)

#### jira_search

```text
mcp__atl__jira_search({
  jql: string,
  fields?: string,
  limit?: number,
  start_at?: number,
  projects_filter?: string,
  expand?: string
})
```text

**Purpose:** Search issues using JQL (Jira Query Language)
**Returns:** Paginated search results

**Parameters:**

- `jql` (required): JQL query string
- `fields` (optional): Fields to return (default: essential fields)
- `limit` (optional): Max results 1-50 (default: 10)
- `start_at` (optional): Pagination offset (default: 0)
- `projects_filter` (optional): Comma-separated project keys
- `expand` (optional): Expand fields

**JQL Examples:**

```text
Find Epics: "issuetype = Epic AND project = PROJ"
Find in Epic: "parent = PROJ-123"
By status: "status = 'In Progress' AND project = PROJ"
By assignee: "assignee = currentUser()"
Recent: "updated >= -7d AND project = PROJ"
By label: "labels = frontend AND project = PROJ"
By priority: "priority = High AND project = PROJ"
```text

#### jira_create_issue

```text
mcp__atl__jira_create_issue({
  project_key: string,
  summary: string,
  issue_type: string,
  assignee?: string,
  description?: string,
  components?: string,
  additional_fields?: object
})
```text

**Purpose:** Create new Jira issue
**Returns:** Created issue object

**Parameters:**

- `project_key` (required): Project key (e.g., "PROJ")
- `summary` (required): Issue title
- `issue_type` (required): Type ("Task", "Bug", "Story", "Epic", "Subtask")
- `assignee` (optional): Email, display name, or account ID
- `description` (optional): Issue description
- `components` (optional): Comma-separated component names
- `additional_fields` (optional): Extra fields like priority, labels, parent, fixVersions

**Additional Fields Examples:**

```javascript
{
  priority: { name: "High" },
  labels: ["frontend", "urgent"],
  parent: "PROJ-123",  // For any issue type
  fixVersions: [{ id: "10020" }],
  customfield_10010: "value"
}
```text

#### jira_batch_create_issues

```text
mcp__atl__jira_batch_create_issues({
  issues: string,  // JSON array
  validate_only?: boolean
})
```text

**Purpose:** Create multiple issues in batch
**Returns:** Created issues or validation results

**Parameters:**

- `issues` (required): JSON array of issue objects
- `validate_only` (optional): Only validate without creating (default: false)

**Issues Array Format:**

```json
[
  {
    "project_key": "PROJ",
    "summary": "Issue 1",
    "issue_type": "Task"
  },
  {
    "project_key": "PROJ",
    "summary": "Issue 2",
    "issue_type": "Bug",
    "components": ["Frontend"]
  }
]
```text

#### jira_update_issue

```text
mcp__atl__jira_update_issue({
  issue_key: string,
  fields: object,
  additional_fields?: object,
  attachments?: string
})
```text

**Purpose:** Update existing issue
**Returns:** Updated issue object and attachment results

**Parameters:**

- `issue_key` (required): Issue key
- `fields` (required): Fields to update (assignee: string identifier)
- `additional_fields` (optional): Extra fields
- `attachments` (optional): Comma-separated file paths or JSON array

**Fields Example:**

```javascript
{
  assignee: "user@example.com",
  summary: "New Summary",
  description: "Updated description",
  priority: { name: "High" }
}
```text

#### jira_delete_issue

```text
mcp__atl__jira_delete_issue({
  issue_key: string
})
```text

**Purpose:** Delete issue
**Returns:** Success confirmation

#### jira_transition_issue

```text
mcp__atl__jira_transition_issue({
  issue_key: string,
  transition_id: string,
  fields?: object,
  comment?: string
})
```text

**Purpose:** Change issue status
**Returns:** Updated issue object

**Parameters:**

- `issue_key` (required): Issue key
- `transition_id` (required): Transition ID (get from `jira_get_transitions`)
- `fields` (optional): Fields to set during transition (e.g., resolution)
- `comment` (optional): Comment for history

**Example Fields:**

```javascript
{
  resolution: {
    name: "Fixed";
  }
}
```text

#### jira_get_transitions

```text
mcp__atl__jira_get_transitions({
  issue_key: string
})
```text

**Purpose:** Get available status transitions
**Returns:** Array of available transitions with IDs

---

### JIRA LINKS & RELATIONSHIPS

#### jira_link_to_epic

```text
mcp__atl__jira_link_to_epic({
  issue_key: string,
  epic_key: string
})
```text

**Purpose:** Link issue to epic
**Returns:** Updated issue object

#### jira_create_issue_link

```text
mcp__atl__jira_create_issue_link({
  link_type: string,
  inward_issue_key: string,
  outward_issue_key: string,
  comment?: string,
  comment_visibility?: object
})
```text

**Purpose:** Create link between issues
**Returns:** Success/failure status

**Parameters:**

- `link_type` (required): Link type (e.g., "Blocks", "Duplicate", "Relates to")
- `inward_issue_key` (required): Source issue
- `outward_issue_key` (required): Target issue
- `comment` (optional): Link comment
- `comment_visibility` (optional): `{type: "group", value: "jira-users"}`

#### jira_create_remote_issue_link

```text
mcp__atl__jira_create_remote_issue_link({
  issue_key: string,
  url: string,
  title: string,
  summary?: string,
  relationship?: string,
  icon_url?: string
})
```text

**Purpose:** Create web link or Confluence link
**Returns:** Success/failure status

**Parameters:**

- `issue_key` (required): Issue to link to
- `url` (required): Web or Confluence URL
- `title` (required): Link display name
- `summary` (optional): Link description
- `relationship` (optional): Relationship type (e.g., "causes", "documentation")
- `icon_url` (optional): 16x16 icon URL

#### jira_remove_issue_link

```text
mcp__atl__jira_remove_issue_link({
  link_id: string
})
```text

**Purpose:** Remove issue link
**Returns:** Success confirmation

#### jira_get_link_types

```text
mcp__atl__jira_get_link_types()
```text

**Purpose:** Get all available link types
**Returns:** Array of link type objects

---

### JIRA METADATA

#### jira_add_comment

```text
mcp__atl__jira_add_comment({
  issue_key: string,
  comment: string
})
```text

**Purpose:** Add comment to issue (Markdown format)
**Returns:** Created comment object

#### jira_add_worklog

```text
mcp__atl__jira_add_worklog({
  issue_key: string,
  time_spent: string,
  comment?: string,
  started?: string,
  original_estimate?: string,
  remaining_estimate?: string
})
```text

**Purpose:** Log work time on issue
**Returns:** Created worklog object

**Parameters:**

- `issue_key` (required): Issue key
- `time_spent` (required): Jira format ("1h 30m", "1d", "30m", "4h")
- `comment` (optional): Worklog comment (Markdown)
- `started` (optional): Start time ISO format (default: now)
- `original_estimate` (optional): New original estimate
- `remaining_estimate` (optional): New remaining estimate

#### jira_get_worklog

```text
mcp__atl__jira_get_worklog({
  issue_key: string
})
```text

**Purpose:** Get worklog entries
**Returns:** Worklog entries array

#### jira_download_attachments

```text
mcp__atl__jira_download_attachments({
  issue_key: string,
  target_dir: string
})
```text

**Purpose:** Download issue attachments
**Returns:** Download operation results

---

### JIRA PROJECT MANAGEMENT

#### jira_get_all_projects

```text
mcp__atl__jira_get_all_projects({
  include_archived?: boolean
})
```text

**Purpose:** Get accessible projects
**Returns:** Array of project objects (keys in uppercase)

**Parameters:**

- `include_archived` (optional): Include archived projects (default: false)

#### jira_get_project_issues

```text
mcp__atl__jira_get_project_issues({
  project_key: string,
  limit?: number,
  start_at?: number
})
```text

**Purpose:** Get all issues for project
**Returns:** Paginated issue list

**Parameters:**

- `project_key` (required): Project key
- `limit` (optional): Max results 1-50 (default: 10)
- `start_at` (optional): Pagination offset (default: 0)

#### jira_get_project_versions

```text
mcp__atl__jira_get_project_versions({
  project_key: string
})
```text

**Purpose:** Get fix versions for project
**Returns:** Array of version objects

#### jira_create_version

```text
mcp__atl__jira_create_version({
  project_key: string,
  name: string,
  start_date?: string,
  release_date?: string,
  description?: string
})
```text

**Purpose:** Create fix version
**Returns:** Created version object

**Parameters:**

- `project_key` (required): Project key
- `name` (required): Version name
- `start_date` (optional): Start date (YYYY-MM-DD)
- `release_date` (optional): Release date (YYYY-MM-DD)
- `description` (optional): Version description

#### jira_batch_create_versions

```text
mcp__atl__jira_batch_create_versions({
  project_key: string,
  versions: string  // JSON array
})
```text

**Purpose:** Create multiple versions
**Returns:** Array of results

**Versions Array Format:**

```json
[
  {
    "name": "v1.0",
    "startDate": "2025-01-01",
    "releaseDate": "2025-02-01",
    "description": "First release"
  },
  { "name": "v2.0" }
]
```text

---

### JIRA AGILE (BOARDS & SPRINTS)

#### jira_get_agile_boards

```text
mcp__atl__jira_get_agile_boards({
  board_name?: string,
  project_key?: string,
  board_type?: string,
  start_at?: number,
  limit?: number
})
```text

**Purpose:** Get boards by name, project, or type
**Returns:** Array of board objects

**Parameters:**

- `board_name` (optional): Name fuzzy search
- `project_key` (optional): Filter by project
- `board_type` (optional): "scrum" or "kanban"
- `start_at` (optional): Pagination offset (default: 0)
- `limit` (optional): Max results 1-50 (default: 10)

#### jira_get_board_issues

```text
mcp__atl__jira_get_board_issues({
  board_id: string,
  jql: string,
  fields?: string,
  start_at?: number,
  limit?: number,
  expand?: string
})
```text

**Purpose:** Get board issues filtered by JQL
**Returns:** Paginated issue list

**Parameters:**

- `board_id` (required): Board ID
- `jql` (required): JQL query
- `fields` (optional): Fields to return (default: essential)
- `start_at` (optional): Pagination offset (default: 0)
- `limit` (optional): Max results 1-50 (default: 10)
- `expand` (optional): Expand fields (default: "version")

#### jira_get_sprints_from_board

```text
mcp__atl__jira_get_sprints_from_board({
  board_id: string,
  state?: string,
  start_at?: number,
  limit?: number
})
```text

**Purpose:** Get sprints from board by state
**Returns:** Array of sprint objects

**Parameters:**

- `board_id` (required): Board ID
- `state` (optional): "active", "future", "closed" (none = all)
- `start_at` (optional): Pagination offset (default: 0)
- `limit` (optional): Max results 1-50 (default: 10)

#### jira_get_sprint_issues

```text
mcp__atl__jira_get_sprint_issues({
  sprint_id: string,
  fields?: string,
  start_at?: number,
  limit?: number
})
```text

**Purpose:** Get issues in sprint
**Returns:** Paginated issue list

**Parameters:**

- `sprint_id` (required): Sprint ID
- `fields` (optional): Fields to return (default: essential)
- `start_at` (optional): Pagination offset (default: 0)
- `limit` (optional): Max results 1-50 (default: 10)

#### jira_create_sprint

```text
mcp__atl__jira_create_sprint({
  board_id: string,
  sprint_name: string,
  start_date: string,
  end_date: string,
  goal?: string
})
```text

**Purpose:** Create sprint for board
**Returns:** Created sprint object

**Parameters:**

- `board_id` (required): Board ID
- `sprint_name` (required): Sprint name
- `start_date` (required): Start time ISO 8601
- `end_date` (required): End time ISO 8601
- `goal` (optional): Sprint goal

#### jira_update_sprint

```text
mcp__atl__jira_update_sprint({
  sprint_id: string,
  sprint_name?: string,
  state?: string,
  start_date?: string,
  end_date?: string,
  goal?: string
})
```text

**Purpose:** Update sprint
**Returns:** Updated sprint object

**Parameters:**

- `sprint_id` (required): Sprint ID
- `sprint_name` (optional): New name
- `state` (optional): "future", "active", "closed"
- `start_date` (optional): New start date
- `end_date` (optional): New end date
- `goal` (optional): New goal

---

### JIRA ADVANCED

#### jira_batch_get_changelogs

```text
mcp__atl__jira_batch_get_changelogs({
  issue_ids_or_keys: string[],
  fields?: string[],
  limit?: number
})
```text

**Purpose:** Get changelogs for multiple issues (Cloud only)
**Returns:** Issues with changelogs

**Parameters:**

- `issue_ids_or_keys` (required): Issue IDs/keys array
- `fields` (optional): Filter by fields (e.g., ["status", "assignee"])
- `limit` (optional): Max changelogs per issue (default: -1 for all)

#### jira_search_fields

```text
mcp__atl__jira_search_fields({
  keyword?: string,
  limit?: number,
  refresh?: boolean
})
```text

**Purpose:** Search fields by keyword with fuzzy match
**Returns:** Matching field definitions

**Parameters:**

- `keyword` (optional): Search keyword (empty = list first fields)
- `limit` (optional): Max results (default: 10)
- `refresh` (optional): Force refresh field list (default: false)

#### jira_get_user_profile

```text
mcp__atl__jira_get_user_profile({
  user_identifier: string
})
```text

**Purpose:** Get user profile
**Returns:** User profile object

**Parameters:**

- `user_identifier` (required): Email, username, key, or account ID

---

### CONFLUENCE OPERATIONS

#### confluence_search

```text
mcp__atl__confluence_search({
  query: string,
  limit?: number,
  spaces_filter?: string
})
```text

**Purpose:** Search Confluence content (text or CQL)
**Returns:** Simplified page objects

**Parameters:**

- `query` (required): Text search or CQL query
- `limit` (optional): Max results 1-50 (default: 10)
- `spaces_filter` (optional): Comma-separated space keys

**CQL Examples:**

```text
Basic: "type=page AND space=DEV"
Personal space: "space=\"~username\"" (quote required)
Title search: "title~\"Meeting Notes\""
Site search: "siteSearch ~ \"important concept\""
Text search: "text ~ \"important concept\""
Recent: "created >= \"2023-01-01\""
With label: "label=documentation"
Modified: "lastModified > startOfMonth(\"-1M\")"
This year: "creator = currentUser() AND lastModified > startOfYear()"
Contributed: "contributor = currentUser() AND lastModified > startOfWeek()"
Watched: "watcher = \"user@domain.com\" AND type = page"
Exact phrase: "text ~ \"\\\"Urgent Review Required\\\"\" AND label = \"pending-approval\""
Title wildcards: "title ~ \"Minutes*\" AND (space = \"HR\" OR space = \"Marketing\")"
```text

#### confluence_get_page

```text
mcp__atl__confluence_get_page({
  page_id?: string,
  title?: string,
  space_key?: string,
  include_metadata?: boolean,
  convert_to_markdown?: boolean
})
```text

**Purpose:** Get page content by ID or title+space
**Returns:** Page content and/or metadata

**Parameters:**

- `page_id` (optional): Page ID (if provided, title/space_key ignored)
- `title` (optional): Exact page title (requires space_key)
- `space_key` (optional): Space key (required with title)
- `include_metadata` (optional): Include metadata (default: true)
- `convert_to_markdown` (optional): Convert to markdown (default: true, HTML uses more tokens)

#### confluence_get_page_children

```text
mcp__atl__confluence_get_page_children({
  parent_id: string,
  expand?: string,
  limit?: number,
  include_content?: boolean,
  convert_to_markdown?: boolean,
  start?: number
})
```text

**Purpose:** Get child pages
**Returns:** Array of child page objects

**Parameters:**

- `parent_id` (required): Parent page ID
- `expand` (optional): Expand fields (default: "version")
- `limit` (optional): Max results 1-50 (default: 25)
- `include_content` (optional): Include content (default: false)
- `convert_to_markdown` (optional): Convert to markdown if include_content (default: true)
- `start` (optional): Pagination offset (default: 0)

#### confluence_create_page

```text
mcp__atl__confluence_create_page({
  space_key: string,
  title: string,
  content: string,
  parent_id?: string,
  content_format?: string,
  enable_heading_anchors?: boolean
})
```text

**Purpose:** Create Confluence page
**Returns:** Created page object

**Parameters:**

- `space_key` (required): Space key (e.g., "DEV", "TEAM")
- `title` (required): Page title
- `content` (required): Page content
- `parent_id` (optional): Parent page ID
- `content_format` (optional): "markdown" (default), "wiki", "storage"
- `enable_heading_anchors` (optional): Auto heading anchors (default: false, markdown only)

#### confluence_update_page

```text
mcp__atl__confluence_update_page({
  page_id: string,
  title: string,
  content: string,
  is_minor_edit?: boolean,
  version_comment?: string,
  parent_id?: string,
  content_format?: string,
  enable_heading_anchors?: boolean
})
```text

**Purpose:** Update existing page
**Returns:** Updated page object

**Parameters:**

- `page_id` (required): Page ID
- `title` (required): New title
- `content` (required): New content
- `is_minor_edit` (optional): Minor edit flag (default: false)
- `version_comment` (optional): Version comment
- `parent_id` (optional): New parent page ID
- `content_format` (optional): "markdown" (default), "wiki", "storage"
- `enable_heading_anchors` (optional): Auto heading anchors (default: false, markdown only)

#### confluence_delete_page

```text
mcp__atl__confluence_delete_page({
  page_id: string
})
```text

**Purpose:** Delete page
**Returns:** Success/failure status

#### confluence_add_comment

```text
mcp__atl__confluence_add_comment({
  page_id: string,
  content: string
})
```text

**Purpose:** Add page comment (Markdown format)
**Returns:** Created comment object

#### confluence_get_comments

```text
mcp__atl__confluence_get_comments({
  page_id: string
})
```text

**Purpose:** Get page comments
**Returns:** Array of comment objects

#### confluence_add_label

```text
mcp__atl__confluence_add_label({
  page_id: string,
  name: string
})
```text

**Purpose:** Add label to page
**Returns:** Updated label list

#### confluence_get_labels

```text
mcp__atl__confluence_get_labels({
  page_id: string
})
```text

**Purpose:** Get page labels
**Returns:** Array of label objects

#### confluence_search_user

```text
mcp__atl__confluence_search_user({
  query: string,
  limit?: number
})
```text

**Purpose:** Search users with CQL
**Returns:** User search results

**Parameters:**

- `query` (required): CQL query (e.g., `user.fullname ~ "First Last"`)
- `limit` (optional): Max results 1-50 (default: 10)

---

## EXECUTION PATTERNS

### Pattern: Create Issue with Full Metadata

```text
STEP 1: mcp__atl__jira_get_all_projects()
SELECT: target project

STEP 2: mcp__atl__jira_create_issue({
  project_key: "PROJ",
  summary: "Implement user authentication",
  issue_type: "Task",
  assignee: "dev@example.com",
  description: "Detailed description",
  components: "Backend,Security",
  additional_fields: {
    priority: { name: "High" },
    labels: ["security", "api"]
  }
})

STEP 3: mcp__atl__jira_link_to_epic({
  issue_key: "PROJ-456",
  epic_key: "PROJ-123"
})
```text

### Pattern: Sprint Planning Workflow

```text
STEP 1: mcp__atl__jira_get_agile_boards({
  project_key: "PROJ",
  board_type: "scrum"
})

STEP 2: mcp__atl__jira_create_sprint({
  board_id: "1000",
  sprint_name: "Sprint 24",
  start_date: "2025-01-20T09:00:00.000+0000",
  end_date: "2025-02-03T17:00:00.000+0000",
  goal: "Complete authentication module"
})

STEP 3: mcp__atl__jira_search({
  jql: "project = PROJ AND status = 'To Do' AND priority = High",
  limit: 20
})

STEP 4: UPDATE issues to sprint (via jira_update_issue)
```text

### Pattern: Issue Transition with Resolution

```text
STEP 1: mcp__atl__jira_get_transitions({
  issue_key: "PROJ-123"
})
IDENTIFY: transition ID for "Done"

STEP 2: mcp__atl__jira_transition_issue({
  issue_key: "PROJ-123",
  transition_id: "31",
  fields: { resolution: { name: "Fixed" } },
  comment: "Implemented and tested successfully"
})
```text

### Pattern: Confluence Documentation Creation

```text
STEP 1: mcp__atl__confluence_search({
  query: "space=DEV AND title~\"API*\"",
  limit: 5
})
IDENTIFY: parent page

STEP 2: mcp__atl__confluence_create_page({
  space_key: "DEV",
  title: "Authentication API",
  content: "# Authentication API\n\nEndpoints...",
  parent_id: "123456",
  content_format: "markdown"
})

STEP 3: mcp__atl__confluence_add_label({
  page_id: "789012",
  name: "api-docs"
})
```text

### Pattern: Batch Issue Creation

```text
STEP 1: mcp__atl__jira_batch_create_issues({
  issues: JSON.stringify([
    {
      project_key: "PROJ",
      summary: "Task 1: Setup environment",
      issue_type: "Task"
    },
    {
      project_key: "PROJ",
      summary: "Task 2: Implement core logic",
      issue_type: "Task",
      components: ["Backend"]
    },
    {
      project_key: "PROJ",
      summary: "Task 3: Write tests",
      issue_type: "Task"
    }
  ])
})
```text

### Pattern: Research and Document

```text
STEP 1: mcp__atl__jira_search({
  jql: "project = PROJ AND resolution = Fixed AND updated >= -30d",
  fields: "summary,description,resolution",
  limit: 50
})

STEP 2: ANALYZE resolved issues

STEP 3: mcp__atl__confluence_create_page({
  space_key: "TEAM",
  title: "Sprint Retrospective - January 2025",
  content: "# Achievements\n\n...\n\n# Challenges\n\n...",
  content_format: "markdown"
})

STEP 4: mcp__claude-flow__memory_usage({
  action: "store",
  key: "sprint_retro_jan2025",
  value: "Key findings and action items",
  namespace: "project"
})
```text

---

## WHEN TO USE

```text
USE ATL FOR:
  ✅ Jira issue management (CRUD operations)
  ✅ Sprint and board operations
  ✅ Issue linking and relationships
  ✅ Confluence page management
  ✅ Documentation in Confluence
  ✅ Team coordination via Jira/Confluence
  ✅ Project tracking and reporting
  ✅ Agile workflow management

DO NOT USE FOR:
  ❌ Code repository operations (use repomix)
  ❌ General web research (use googler)
  ❌ Library documentation (use context7)
  ❌ File system operations (use file tools)
```text

---

## INTEGRATION PATTERNS

### With Claude-Flow Memory

```text
STEP 1: mcp__atl__jira_search({
  jql: "project = PROJ AND labels = architecture",
  limit: 10
})

STEP 2: mcp__claude-flow__memory_usage({
  action: "store",
  key: "architecture_decisions",
  value: "Architecture issues and decisions from Jira",
  namespace: "architecture"
})
```text

### With Googler Research

```text
STEP 1: mcp__googler__research_topic({
  query: "microservices best practices 2024",
  num_results: 3
})

STEP 2: mcp__atl__confluence_create_page({
  space_key: "ARCH",
  title: "Microservices Research",
  content: "Research findings from web sources..."
})

STEP 3: mcp__atl__jira_create_issue({
  project_key: "PROJ",
  summary: "Evaluate microservices architecture",
  issue_type: "Story",
  description: "Based on research, evaluate microservices approach"
})
```text

### With Context7 Documentation

```text
STEP 1: mcp__context7__get-library-docs({
  context7CompatibleLibraryID: "/expressjs/express",
  topic: "authentication"
})

STEP 2: mcp__atl__confluence_create_page({
  space_key: "DEV",
  title: "Express Authentication Guide",
  content: "Official Express.js authentication patterns..."
})

STEP 3: mcp__atl__jira_create_issue({
  project_key: "PROJ",
  summary: "Implement Express authentication",
  issue_type: "Task"
})

STEP 4: mcp__atl__jira_create_remote_issue_link({
  issue_key: "PROJ-123",
  url: "https://confluence.example.com/display/DEV/Express+Auth",
  title: "Authentication Implementation Guide"
})
```text

---

## JQL QUERY PATTERNS

### Find by Status and Priority

```text
"status = 'In Progress' AND priority = High AND project = PROJ"
```text

### Find Unassigned Issues

```text
"assignee is EMPTY AND project = PROJ AND status != Done"
```text

### Find Issues Modified Recently

```text
"updated >= -7d AND project = PROJ ORDER BY updated DESC"
```text

### Find Blocked Issues

```text
"status = Blocked AND project = PROJ"
```text

### Find Issues by Component

```text
"component = Backend AND status != Done AND project = PROJ"
```text

### Find Overdue Issues

```text
"duedate < now() AND status != Done AND project = PROJ"
```text

### Find Issues by Sprint

```text
"sprint = 'Sprint 24' AND project = PROJ"
```text

### Find Epic Children

```text
"parent = PROJ-123"
```text

---

## CONFLUENCE CQL PATTERNS

### Find Pages by Space

```text
"type=page AND space=DEV"
```text

### Find Recent Pages

```text
"type=page AND lastModified > startOfWeek() AND space=TEAM"
```text

### Find by Creator

```text
"creator = currentUser() AND type=page"
```text

### Find by Label

```text
"label=api-docs AND space=DEV"
```text

### Find Pages with Text

```text
"siteSearch ~ \"authentication\" AND space=DEV"
```text

---

## ERROR HANDLING

### Issue Creation Failures

```text
IF jira_create_issue fails:
  1. CHECK project_key exists (jira_get_all_projects)
  2. VERIFY issue_type is valid for project
  3. CHECK required fields for issue type
  4. VERIFY assignee exists (jira_get_user_profile)
```text

### Transition Failures

```text
IF jira_transition_issue fails:
  1. GET available transitions (jira_get_transitions)
  2. VERIFY transition_id is valid
  3. CHECK required fields for transition
  4. ENSURE current status allows transition
```text

### Confluence Access Issues

```text
IF confluence_get_page fails:
  1. VERIFY page_id or title+space_key combination
  2. CHECK permissions for space
  3. TRY confluence_search to find page
  4. VERIFY space_key is correct
```text

---

## PERFORMANCE OPTIMIZATION

### Batch Operations

```text
USE batch tools when possible:
  - jira_batch_create_issues (multiple issues)
  - jira_batch_create_versions (multiple versions)
  - jira_batch_get_changelogs (multiple changelogs)

FASTER than individual calls
FEWER API requests
BETTER quota management
```text

### Field Selection

```text
EFFICIENT:
  - Specify only needed fields
  - Use default essential fields for lists
  - Request "*all" only when necessary

INEFFICIENT:
  - Always requesting all fields
  - Expanding all optional fields
```text

### Pagination

```text
OPTIMAL:
  - Use limit=10-20 for interactive work
  - Use limit=50 for batch processing
  - Track start_at for pagination
  - Stop when sufficient results found
```text

---

## DECISION TREE

```text
START
  |
  ├─ Need to manage Jira issues? → YES → ATL jira_* tools
  |
  ├─ Need to track sprints/boards? → YES → ATL jira_get_agile_boards
  |
  ├─ Need to create documentation? → YES → ATL confluence_create_page
  |
  ├─ Need to search Confluence? → YES → ATL confluence_search
  |
  ├─ Need to link issues/pages? → YES → ATL jira_create_issue_link
  |
  └─ Need to track work time? → YES → ATL jira_add_worklog
```text

---

## QUICK REFERENCE

```text
JIRA CORE:
  mcp__atl__jira_get_issue({ issue_key })
  mcp__atl__jira_search({ jql, limit? })
  mcp__atl__jira_create_issue({ project_key, summary, issue_type })
  mcp__atl__jira_update_issue({ issue_key, fields })
  mcp__atl__jira_transition_issue({ issue_key, transition_id })

JIRA AGILE:
  mcp__atl__jira_get_agile_boards({ project_key?, board_type? })
  mcp__atl__jira_get_sprints_from_board({ board_id, state? })
  mcp__atl__jira_create_sprint({ board_id, sprint_name, start_date, end_date })

CONFLUENCE:
  mcp__atl__confluence_search({ query, limit? })
  mcp__atl__confluence_get_page({ page_id OR title+space_key })
  mcp__atl__confluence_create_page({ space_key, title, content })
  mcp__atl__confluence_update_page({ page_id, title, content })

WHEN TO USE:
  Issue tracking, sprint planning, documentation, team coordination

WHEN NOT TO USE:
  Code operations, web research, library docs, file system
```text

---

**MCP Server:** atl
**Status:** Connected
**Provider:** mcp-atlassian
**Python:** 3.10+ required
**Optimized for:** LLM direct execution
````

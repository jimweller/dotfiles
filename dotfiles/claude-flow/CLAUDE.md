# Claude Code Configuration - Enhanced Development Environment

**Target:** Claude Code AI Assistant (Sonnet 4.5+)
**Mode:** Claude-Flow + Multi-MCP Integration
**Last Updated:** 2025-11-15

---

## 🚨 CRITICAL: CONCURRENT EXECUTION & FILE MANAGEMENT

**ABSOLUTE RULES**:
1. ALL operations MUST be concurrent/parallel in a single message
2. **NEVER save working files, text/mds and tests to the root folder**
3. ALWAYS organize files in appropriate subdirectories
4. **USE CLAUDE CODE'S TASK TOOL** for spawning agents concurrently, not just MCP

### ⚡ GOLDEN RULE: "1 MESSAGE = ALL RELATED OPERATIONS"

**MANDATORY PATTERNS:**
- **TodoWrite**: ALWAYS batch ALL todos in ONE call (5-10+ todos minimum)
- **Task tool (Claude Code)**: ALWAYS spawn ALL agents in ONE message with full instructions
- **File operations**: ALWAYS batch ALL reads/writes/edits in ONE message
- **Bash commands**: ALWAYS batch ALL terminal operations in ONE message
- **Memory operations**: ALWAYS batch ALL memory store/retrieve in ONE message

### 🎯 CRITICAL: Claude Code Task Tool for Agent Execution

**Claude Code's Task tool is the PRIMARY way to spawn agents:**
```javascript
// ✅ CORRECT: Use Claude Code's Task tool for parallel agent execution
[Single Message]:
  Task("Research agent", "Analyze requirements and patterns...", "researcher")
  Task("Coder agent", "Implement core features...", "coder")
  Task("Tester agent", "Create comprehensive tests...", "tester")
  Task("Reviewer agent", "Review code quality...", "reviewer")
  Task("Architect agent", "Design system architecture...", "system-architect")
```

**MCP tools are ONLY for coordination setup:**
- `mcp__claude-flow__swarm_init` - Initialize coordination topology
- `mcp__claude-flow__agent_spawn` - Define agent types for coordination
- `mcp__claude-flow__task_orchestrate` - Orchestrate high-level workflows

### 📁 File Organization Rules

**NEVER save to root folder. Use these directories:**
- `/src` - Source code files
- `/tests` - Test files
- `/docs` - Documentation and markdown files
- `/config` - Configuration files
- `/scripts` - Utility scripts
- `/examples` - Example code

---

## 📚 AVAILABLE MCP SERVERS

Connected and verified:
- `claude-flow` - Multi-agent orchestration, memory, swarm coordination
- `context7` - Official library documentation retrieval
- `googler` - Web research, scraping, AI analysis
- `agentdb` - Reinforcement learning, experience replay, vector memory
- `repomix` - Codebase analysis and packaging
- `atl` - Jira/Confluence integration (optional)
- `ide` - VS Code integration (optional)

---

## 🎯 TOOL EXECUTION HIERARCHY

### Layer 1: Claude Code Task Tool (PRIMARY - Actual Work)
- Spawns real agents that execute tasks concurrently
- File operations (Read, Write, Edit, Glob, Grep)
- Code generation and programming
- Bash commands and system operations
- Git operations and package management
- Testing and debugging
- TodoWrite and task management

### Layer 2: MCP Tools (COORDINATION)
- **claude-flow**: Swarm coordination, memory, neural features
- **context7**: Official library documentation
- **googler**: Web research and analysis
- **agentdb**: AI learning and memory patterns
- **repomix**: Codebase analysis and packaging
- **atl**: Jira/Confluence management

### Layer 3: NPX Subprocess (ORCHESTRATION)
- `npx claude-flow@alpha swarm "<task>" --claude` - Opens Claude Code CLI
- `npx claude-flow@alpha hive-mind spawn "<objective>" --claude` - Multi-instance coordination
- `npx claude-flow@alpha memory store/query` - Memory operations
- Slash commands in `.claude/commands/`

**KEY PRINCIPLE**: MCP coordinates strategy → Claude Code Task tool executes → Hooks enable coordination

---

## 🚀 CORE MCP TOOLS REFERENCE

### Claude-Flow Native Tools

**Coordination:**
```
mcp__claude-flow__swarm_init(topology, maxAgents, strategy)
mcp__claude-flow__agent_spawn(type, name?, capabilities?, swarmId?)
mcp__claude-flow__task_orchestrate(task, strategy?, priority?, dependencies?)
mcp__claude-flow__swarm_status(swarmId?)
mcp__claude-flow__agent_list(swarmId?)
```

**Memory & Neural:**
```
mcp__claude-flow__memory_usage(action, key?, value?, namespace?, ttl?)
mcp__claude-flow__memory_search(pattern, namespace?, limit?)
mcp__claude-flow__neural_train(pattern_type, training_data, epochs?)
mcp__claude-flow__neural_patterns(action, operation?, outcome?, metadata?)
```

**Performance:**
```
mcp__claude-flow__performance_report(format?, timeframe?)
mcp__claude-flow__bottleneck_analyze(component?, metrics?)
mcp__claude-flow__agent_metrics(agentId)
```

### Context7 Tools (Official Documentation)

```
mcp__context7__resolve-library-id({ libraryName: string })
mcp__context7__get-library-docs({
  context7CompatibleLibraryID: string,
  topic?: string,
  tokens?: number
})
```

**Use for:** Official API docs, library references, SDK usage

### Googler Tools (Web Research)

```
mcp__googler__google_search({ query: string, num_results?: number })
mcp__googler__scrape_page({ url: string })
mcp__googler__analyze_with_gemini({ text: string, model?: string })
mcp__googler__research_topic({ query: string, num_results?: number })
```

**Use for:** Best practices, comparisons, trends, tutorials, real-world examples

### AgentDB Tools (AI Learning)

```
mcp__agentdb__agentdb_init({ db_path?: string, reset?: boolean })
mcp__agentdb__agentdb_insert({ text: string, metadata?, tags?, session_id? })
mcp__agentdb__agentdb_search({ query: string, k?: number, filters? })
mcp__agentdb__reflexion_store({ session_id, task, reward, success, critique? })
mcp__agentdb__learning_start_session({ user_id, session_type, config })
```

**Use for:** Experience replay, pattern learning, reinforcement learning

---

## 🚀 STANDARD OPERATING PROCEDURES

### SOP-1: Feature Development with Research

```
STEP 1: Research (if needed)
  IF need official docs:
    USE: mcp__context7__resolve-library-id → mcp__context7__get-library-docs
  IF need best practices:
    USE: mcp__googler__research_topic({ query: "topic 2024", num_results: 3 })

STEP 2: Check Memory
  USE: mcp__claude-flow__memory_search({ pattern: "feature_context", namespace: "project" })

STEP 3: Coordinate (optional for complex tasks)
  USE: mcp__claude-flow__swarm_init({ topology: "mesh", maxAgents: 6 })
  USE: mcp__claude-flow__agent_spawn({ type: "researcher" })
  USE: mcp__claude-flow__agent_spawn({ type: "coder" })
  USE: mcp__claude-flow__agent_spawn({ type: "tester" })

STEP 4: Execute with Task Tool (ALL IN ONE MESSAGE)
  Task("Research", "prompt with hooks coordination", "researcher")
  Task("Coder", "prompt with memory storage", "coder")
  Task("Tester", "prompt with agentdb learning", "tester")
  TodoWrite({ todos: [8-10 batched todos] })
  Bash "mkdir -p src tests docs"
  Write "src/feature.js"
  Write "tests/feature.test.js"

STEP 5: Store Knowledge
  USE: mcp__claude-flow__memory_usage({
    action: "store",
    key: "feature_implementation",
    value: "details",
    namespace: "features"
  })
  USE: mcp__agentdb__reflexion_store({
    session_id: "dev",
    task: "feature implementation",
    reward: 0.9,
    success: true
  })
```

### SOP-2: Documentation Research Pattern

```
FOR official_library_docs:
  STEP 1: mcp__context7__resolve-library-id({ libraryName: "library" })
  STEP 2: mcp__context7__get-library-docs({
    context7CompatibleLibraryID: "id",
    topic: "specific_topic"
  })
  STEP 3: Store in memory

FOR real_world_examples OR best_practices:
  STEP 1: mcp__googler__research_topic({
    query: "specific_query 2024",
    num_results: 3-5
  })
  STEP 2: Store findings

COMBINED APPROACH (Recommended):
  STEP 1: Research best practices (Googler)
  STEP 2: Get official docs (Context7)
  STEP 3: Store synthesized knowledge (Claude-Flow)
  STEP 4: Implement with Task tool
```

### SOP-3: Bug Investigation with Learning

```
STEP 1: Search Existing Solutions
  USE: mcp__claude-flow__memory_search({ pattern: "bug_keywords", namespace: "bugs" })
  USE: mcp__agentdb__agentdb_search({ query: "error_description", k: 5 })

STEP 2: Research Fix Approaches
  USE: mcp__googler__research_topic({
    query: "error_message solution 2024",
    num_results: 3
  })

STEP 3: Analyze with Task Tool
  Task("Analyst", "Analyze root cause with hooks", "analyst")

STEP 4: Store Solution and Learning
  USE: mcp__claude-flow__memory_usage({ action: "store", namespace: "bugs" })
  USE: mcp__agentdb__reflexion_store({
    task: "bug_fix",
    reward: 1.0,
    success: true,
    critique: "lessons_learned"
  })
```

---

## 🎯 AGENT EXECUTION PATTERN

### Complete Workflow Example:

```javascript
// SINGLE MESSAGE - All operations together

// 1. Optional: MCP coordination setup for complex tasks
mcp__claude-flow__swarm_init({ topology: "hierarchical", maxAgents: 8 })
mcp__claude-flow__agent_spawn({ type: "researcher", name: "doc-researcher" })
mcp__claude-flow__agent_spawn({ type: "coder", name: "backend-dev" })
mcp__claude-flow__agent_spawn({ type: "tester", name: "test-engineer" })

// 2. Research if needed
mcp__googler__research_topic({ query: "REST API authentication 2024", num_results: 3 })
mcp__context7__resolve-library-id({ libraryName: "express" })
mcp__context7__get-library-docs({ context7CompatibleLibraryID: "/expressjs/express", topic: "authentication" })

// 3. Task tool spawns REAL agents (PRIMARY EXECUTION)
Task("Backend Developer", `
Build REST API with Express authentication.
COORDINATION: Use hooks for pre-task and post-task coordination.
MEMORY: Store API design in namespace 'api'.
LEARNING: Record patterns in agentdb for future reference.
`, "backend-dev")

Task("Test Engineer", `
Create comprehensive Jest test suite.
COORDINATION: Check memory for API contracts from backend.
MEMORY: Store test patterns in namespace 'testing'.
LEARNING: Record successful test strategies in agentdb.
`, "tester")

Task("Documentation Writer", `
Generate API documentation from code.
COORDINATION: Use hooks to notify team when complete.
MEMORY: Store docs structure in namespace 'docs'.
`, "documenter")

// 4. Batch ALL todos
TodoWrite({ todos: [
  {content: "Research API patterns", status: "completed", activeForm: "Researching API patterns"},
  {content: "Design authentication flow", status: "in_progress", activeForm: "Designing authentication"},
  {content: "Implement middleware", status: "pending", activeForm: "Implementing middleware"},
  {content: "Create route handlers", status: "pending", activeForm: "Creating route handlers"},
  {content: "Write unit tests", status: "pending", activeForm: "Writing unit tests"},
  {content: "Integration testing", status: "pending", activeForm: "Testing integration"},
  {content: "Generate API docs", status: "pending", activeForm: "Generating docs"},
  {content: "Performance optimization", status: "pending", activeForm: "Optimizing performance"}
]})

// 5. Batch file operations
Bash "mkdir -p src/{routes,middleware,controllers} tests docs"
Write "src/server.js"
Write "src/routes/auth.js"
Write "src/middleware/auth.js"
Write "tests/auth.test.js"
Write "docs/API.md"

// 6. Store results in memory
mcp__claude-flow__memory_usage({
  action: "store",
  key: "auth_implementation",
  value: "Express JWT authentication with bcrypt",
  namespace: "api"
})
```

---

## 🔗 ADVANCED INTEGRATION PATTERNS

### Pattern 1: Complete Feature Development with All Tools

```javascript
// SINGLE MESSAGE - Complete feature implementation

// 1. Analyze existing codebase (Repomix)
mcp__repomix__pack_codebase({
  directory: "/path/to/project",
  style: "xml",
  includePatterns: "src/**/*.{js,ts}"
})

mcp__repomix__grep_repomix_output({
  outputId: "out_123",
  pattern: "class.*Service|interface.*Repository",
  contextLines: 2
})

// 2. Research best practices (Googler)
mcp__googler__research_topic({
  query: "microservices authentication patterns 2024",
  num_results: 3
})

// 3. Get official library docs (Context7)
mcp__context7__resolve-library-id({ libraryName: "nestjs" })
mcp__context7__get-library-docs({
  context7CompatibleLibraryID: "/nestjs/nest",
  topic: "authentication"
})

// 4. Create Jira epic and tasks (ATL)
mcp__atl__jira_create_issue({
  project_key: "PROJ",
  summary: "Implement microservices authentication",
  issue_type: "Epic",
  description: "Based on research and codebase analysis..."
})

mcp__atl__jira_batch_create_issues({
  issues: JSON.stringify([
    { project_key: "PROJ", summary: "Task 1: Setup auth service", issue_type: "Task" },
    { project_key: "PROJ", summary: "Task 2: Implement JWT", issue_type: "Task" },
    { project_key: "PROJ", summary: "Task 3: Write tests", issue_type: "Task" }
  ])
})

// 5. Initialize coordination (Claude-Flow MCP)
mcp__claude-flow__swarm_init({ topology: "hierarchical", maxAgents: 6 })

// 6. Spawn agents for execution (Task Tool - PRIMARY)
Task("Backend Developer", `
Implement NestJS authentication service.
CONTEXT: Check memory for researched patterns.
CODEBASE: Use repomix output_id out_123 for existing patterns.
COORDINATION: Use hooks for pre/post operations.
`, "backend-dev")

Task("Test Engineer", `
Create comprehensive test suite.
CONTEXT: Check memory for test patterns.
COORDINATION: Monitor backend agent via hooks.
`, "tester")

// 7. Batch todos
TodoWrite({ todos: [
  {content: "Analyze codebase architecture", status: "completed"},
  {content: "Research authentication patterns", status: "completed"},
  {content: "Get NestJS docs", status: "completed"},
  {content: "Create Jira epic and tasks", status: "completed"},
  {content: "Implement auth service", status: "in_progress"},
  {content: "Write unit tests", status: "pending"},
  {content: "Integration tests", status: "pending"},
  {content: "Update Confluence docs", status: "pending"}
]})

// 8. Store integrated knowledge (Claude-Flow + AgentDB)
mcp__claude-flow__memory_usage({
  action: "store",
  key: "auth_implementation",
  value: "NestJS microservices auth with JWT, based on 2024 best practices",
  namespace: "features"
})

mcp__agentdb__reflexion_store({
  session_id: "feature-dev",
  task: "microservices authentication",
  reward: 0.85,
  success: true,
  critique: "Successfully integrated research, docs, and codebase analysis"
})
```

### Pattern 2: Code Review with Issue Tracking

```javascript
// SINGLE MESSAGE - Automated code review workflow

// 1. Pack codebase for review (Repomix)
mcp__repomix__pack_codebase({
  directory: "/path/to/feature-branch",
  style: "xml",
  ignorePatterns: "test/**,*.test.js"
})

// 2. Search for issues (Repomix)
mcp__repomix__grep_repomix_output({
  outputId: "out_456",
  pattern: "TODO|FIXME|XXX|HACK",
  ignoreCase: true,
  contextLines: 3
})

mcp__repomix__grep_repomix_output({
  outputId: "out_456",
  pattern: "console\\.log|debugger",
  contextLines: 1
})

mcp__repomix__grep_repomix_output({
  outputId: "out_456",
  pattern: "eval\\(|innerHTML|dangerouslySetInnerHTML",
  contextLines: 2
})

// 3. Create Jira issues for findings (ATL)
mcp__atl__jira_create_issue({
  project_key: "PROJ",
  summary: "Code Review: Remove debug statements",
  issue_type: "Bug",
  priority: { name: "Medium" },
  description: "Found console.log statements in production code..."
})

mcp__atl__jira_create_issue({
  project_key: "PROJ",
  summary: "Code Review: XSS vulnerability in user input",
  issue_type: "Bug",
  priority: { name: "High" },
  labels: ["security"]
})

// 4. Document in Confluence (ATL)
mcp__atl__confluence_create_page({
  space_key: "DEV",
  title: "Code Review - Feature Branch XYZ",
  content: `# Code Review Results\n\n## Security Issues\n...\n\n## Code Quality\n...`,
  content_format: "markdown"
})

// 5. Store review patterns (AgentDB)
mcp__agentdb__agentdb_pattern_store({
  taskType: "code_review",
  approach: "Automated security and quality scanning with Repomix + Jira integration",
  successRate: 0.95
})
```

### Pattern 3: Architecture Documentation Workflow

```javascript
// SINGLE MESSAGE - Complete architecture documentation

// 1. Analyze codebase structure (Repomix)
mcp__repomix__pack_codebase({
  directory: "/path/to/project",
  style: "xml",
  topFilesLength: 20
})

mcp__repomix__grep_repomix_output({
  outputId: "out_789",
  pattern: "class\\s+\\w+Controller|class\\s+\\w+Service",
  contextLines: 5
})

// 2. Research architecture patterns (Googler)
mcp__googler__research_topic({
  query: "microservices architecture patterns best practices 2024",
  num_results: 4
})

// 3. Get framework docs (Context7)
mcp__context7__get-library-docs({
  context7CompatibleLibraryID: "/nestjs/nest",
  topic: "architecture"
})

// 4. Create architecture documentation (ATL Confluence)
mcp__atl__confluence_create_page({
  space_key: "ARCH",
  title: "System Architecture Overview",
  content: `# System Architecture\n\n## Components\n...\n\n## Patterns\n...`,
  content_format: "markdown"
})

// 5. Link to Jira epic (ATL)
mcp__atl__jira_create_issue({
  project_key: "PROJ",
  summary: "Architecture Documentation",
  issue_type: "Epic"
})

mcp__atl__jira_create_remote_issue_link({
  issue_key: "PROJ-123",
  url: "https://confluence.example.com/display/ARCH/System+Architecture",
  title: "Architecture Documentation"
})

// 6. Store architecture decisions (Claude-Flow)
mcp__claude-flow__memory_usage({
  action: "store",
  key: "architecture_overview",
  value: "Microservices with NestJS, event-driven communication...",
  namespace: "architecture"
})
```

### Pattern 4: Sprint Planning with Research

```javascript
// SINGLE MESSAGE - Sprint planning with full context

// 1. Get current sprint status (ATL)
mcp__atl__jira_get_agile_boards({
  project_key: "PROJ",
  board_type: "scrum"
})

mcp__atl__jira_get_sprints_from_board({
  board_id: "1000",
  state: "active"
})

// 2. Analyze codebase for technical debt (Repomix)
mcp__repomix__pack_codebase({
  directory: "/path/to/project"
})

mcp__repomix__grep_repomix_output({
  outputId: "out_abc",
  pattern: "TODO|FIXME|DEPRECATED",
  ignoreCase: true
})

// 3. Research new technologies (Googler + Context7)
mcp__googler__research_topic({
  query: "GraphQL vs REST API 2024 comparison",
  num_results: 3
})

mcp__context7__get-library-docs({
  context7CompatibleLibraryID: "/apollographql/apollo-server",
  topic: "getting started"
})

// 4. Create sprint (ATL)
mcp__atl__jira_create_sprint({
  board_id: "1000",
  sprint_name: "Sprint 25",
  start_date: "2025-01-20T09:00:00.000+0000",
  end_date: "2025-02-03T17:00:00.000+0000",
  goal: "GraphQL API implementation and technical debt reduction"
})

// 5. Create tasks (ATL)
mcp__atl__jira_batch_create_issues({
  issues: JSON.stringify([
    { project_key: "PROJ", summary: "Research GraphQL implementation", issue_type: "Story" },
    { project_key: "PROJ", summary: "Refactor TODO items", issue_type: "Task" },
    { project_key: "PROJ", summary: "Setup Apollo Server", issue_type: "Task" }
  ])
})

// 6. Store sprint context (Claude-Flow)
mcp__claude-flow__memory_usage({
  action: "store",
  key: "sprint25_context",
  value: "Focus: GraphQL migration + tech debt. Research completed.",
  namespace: "project"
})
```

### Pattern 5: Learning from Experience

```javascript
// SINGLE MESSAGE - Experience-based development

// 1. Query past successful patterns (AgentDB)
mcp__agentdb__agentdb_pattern_search({
  task: "API authentication implementation",
  threshold: 0.7,
  k: 5
})

mcp__agentdb__reflexion_retrieve({
  task: "authentication",
  min_reward: 0.8,
  k: 3,
  only_successes: true
})

// 2. Check project memory (Claude-Flow)
mcp__claude-flow__memory_search({
  pattern: "authentication patterns",
  namespace: "patterns"
})

// 3. Get latest docs and research (Context7 + Googler)
mcp__context7__get-library-docs({
  context7CompatibleLibraryID: "/passportjs/passport",
  topic: "strategies"
})

mcp__googler__research_topic({
  query: "OAuth2 implementation best practices 2024",
  num_results: 3
})

// 4. Spawn learning agent (Task Tool)
Task("Smart Developer", `
Implement OAuth2 authentication.
LEARNING: Use patterns from agentdb with >0.8 reward.
MEMORY: Check swarm memory for prior auth implementations.
DOCS: Reference passport.js strategy patterns.
RESEARCH: Apply 2024 OAuth2 best practices.
RECORD: Store implementation in agentdb for future learning.
`, "coder")

// 5. Record new experience (AgentDB)
mcp__agentdb__experience_record({
  session_id: "dev",
  tool_name: "oauth2_implementation",
  action: "implement passport oauth2 strategy",
  outcome: "Successfully implemented with refresh tokens",
  reward: 0.92,
  success: true
})
```

---

## 📋 AGENT COORDINATION PROTOCOL

### Every Agent Spawned via Task Tool MUST:

**1️⃣ BEFORE Work:**
```bash
npx claude-flow@alpha hooks pre-task --description "[task]"
npx claude-flow@alpha hooks session-restore --session-id "swarm-[id]"
```

**2️⃣ DURING Work:**
```bash
npx claude-flow@alpha hooks post-edit --file "[file]" --memory-key "swarm/[agent]/[step]"
npx claude-flow@alpha hooks notify --message "[what was done]"
```

**3️⃣ AFTER Work:**
```bash
npx claude-flow@alpha hooks post-task --task-id "[task]"
npx claude-flow@alpha hooks session-end --export-metrics true
```

---

## 💾 MEMORY ORGANIZATION

### Namespace Structure
```
project       - Project-wide context, decisions, stack
architecture  - Architectural patterns, decisions, rationale
api           - API contracts, endpoints, specifications
patterns      - Coding patterns, conventions, standards
bugs          - Known issues, solutions, root causes
research      - Research findings, sources, comparisons (from Googler)
library_docs  - Documentation summaries (from Context7)
features      - Feature-specific implementation details
sessions      - AgentDB session data
learning      - AgentDB reflexion and patterns
```

### Storage Pattern
```
// Claude-Flow Memory (project context)
mcp__claude-flow__memory_usage({
  action: "store",
  key: "descriptive_key",
  value: "structured_content",
  namespace: "appropriate_namespace",
  ttl: optional_seconds
})

// AgentDB Memory (learning and patterns)
mcp__agentdb__agentdb_insert({
  text: "experience_description",
  metadata: { category: "pattern" },
  tags: ["api", "authentication"],
  session_id: "dev-session"
})

// AgentDB Reflexion (experience replay)
mcp__agentdb__reflexion_store({
  session_id: "dev",
  task: "task_description",
  reward: 0.0-1.0,
  success: true/false,
  critique: "self_reflection"
})
```

---

## 🔍 RESEARCH WORKFLOW INTEGRATION

### Decision Matrix

```
NEED: official_api_docs
  → USE: Context7
  → PATTERN: resolve-library-id → get-library-docs

NEED: best_practices OR comparisons OR trends
  → USE: Googler
  → PATTERN: research_topic with year in query

NEED: learning_from_experience
  → USE: AgentDB
  → PATTERN: agentdb_search → reflexion_retrieve

COMBINED RESEARCH:
  1. Googler: Best practices and real-world examples
  2. Context7: Official documentation
  3. AgentDB: Past experience and learned patterns
  4. Claude-Flow Memory: Store synthesized knowledge
```

### Example: Implementing Stripe Payments

```javascript
// SINGLE MESSAGE - Complete research and implementation

// Research best practices
mcp__googler__research_topic({
  query: "Stripe payment integration best practices 2024",
  num_results: 3
})

// Get official Stripe docs
mcp__context7__resolve-library-id({ libraryName: "stripe" })
mcp__context7__get-library-docs({
  context7CompatibleLibraryID: "/stripe/stripe-node",
  topic: "payment intents"
})

// Check past experience
mcp__agentdb__agentdb_search({
  query: "payment integration patterns",
  k: 5,
  filters: { session_id: "dev" }
})

// Store combined knowledge
mcp__claude-flow__memory_usage({
  action: "store",
  key: "stripe_integration",
  value: `
Best practices: Use Payment Intents API, implement webhooks
Official docs: Create PaymentIntent with amount+currency
Past experience: Handle async webhook events, store customer IDs
Decision: Server-side confirmation with webhook handling
`,
  namespace: "research"
})

// Execute with Task tool
Task("Payment Engineer", `
Implement Stripe payment integration using researched patterns.
Check memory namespace 'research' for stripe_integration guide.
Store implementation patterns in agentdb for future reference.
Use hooks for coordination.
`, "backend-dev")
```

---

## 🚀 AVAILABLE AGENTS (64 Total)

### Core Development
`coder`, `reviewer`, `tester`, `planner`, `researcher`, `backend-dev`, `code-analyzer`, `system-architect`

### Swarm Coordination
`hierarchical-coordinator`, `mesh-coordinator`, `adaptive-coordinator`, `collective-intelligence-coordinator`, `swarm-memory-manager`

### Consensus & Distributed
`byzantine-coordinator`, `raft-manager`, `gossip-coordinator`, `consensus-builder`, `crdt-synchronizer`, `quorum-manager`

### Performance & Optimization
`perf-analyzer`, `performance-benchmarker`, `task-orchestrator`, `memory-coordinator`, `smart-agent`

### GitHub & Repository
`github-modes`, `pr-manager`, `code-review-swarm`, `issue-tracker`, `release-manager`, `workflow-automation`, `repo-architect`

### SPARC Methodology
`sparc-coord`, `sparc-coder`, `specification`, `pseudocode`, `architecture`, `refinement`

### Testing & Validation
`tdd-london-swarm`, `production-validator`

---

## 🎓 QUICK REFERENCE

### Most Used Patterns

**1. Feature Development:**
```
Research (Googler/Context7) → Memory Search → Task Tool → Memory Store
```

**2. Bug Fix:**
```
Memory/AgentDB Search → Research Solution → Task Tool → Reflexion Store
```

**3. Documentation:**
```
Context7 → Synthesize → Task Tool → Memory Store
```

**4. Learning:**
```
Execute Task → AgentDB Reflexion → Pattern Recognition → Future Reuse
```

### Tool Selection

| Need | Primary Tool | Secondary Tool | Tertiary Tool |
|------|--------------|----------------|---------------|
| **Official docs** | Context7 | - | - |
| **Best practices** | Googler | Context7 | AgentDB |
| **Agent execution** | Task Tool | - | - |
| **Coordination** | MCP claude-flow | NPX subprocess | - |
| **Memory** | Claude-Flow | AgentDB | - |
| **Learning** | AgentDB | Claude-Flow | - |

---

## 📚 DOCUMENT REFERENCES

Subordinate documentation with detailed guides:
- @rules/claude-flow.md - Complete Claude-Flow MCP tool reference (80+ tools)
- @rules/context7.md - Context7 documentation retrieval patterns
- @rules/googler.md - Googler research and analysis workflows
- @rules/repomix.md - Repomix codebase packaging and analysis
- @rules/atl.md - ATL Jira and Confluence management

---

## ⚡ PERFORMANCE BENEFITS

- **84.8% SWE-Bench solve rate**
- **32.3% token reduction**
- **2.8-4.4x speed improvement** (parallel execution)
- **27+ neural models** available

---

## 🎯 KEY PRINCIPLES

1. **Task Tool is Primary** - Claude Code's Task tool does actual work
2. **MCP Coordinates** - MCP tools set up coordination and memory
3. **Batch Everything** - ALL operations in single messages
4. **Hooks Enable Coordination** - Agents use hooks for communication
5. **Memory is Persistent** - Store context across sessions
6. **Learning from Experience** - Use AgentDB for pattern recognition
7. **Research Before Coding** - Googler + Context7 + AgentDB

---

## 📝 IMPORTANT INSTRUCTION REMINDERS

- Do what has been asked; nothing more, nothing less
- NEVER create files unless absolutely necessary
- ALWAYS prefer editing existing files to creating new ones
- NEVER proactively create documentation files (*.md) or README files
- Never save working files, text/mds and tests to the root folder
- ALWAYS organize files in appropriate subdirectories

---

**Remember: Claude Flow coordinates → Claude Code Task tool executes → Hooks enable swarm intelligence!**

**VERSION:** 3.0 - Integrated Claude-Flow + Multi-MCP
**MODE:** Native MCP + Task Tool + Subprocess Orchestration
**OPTIMIZED FOR:** LLM parsing and concurrent execution

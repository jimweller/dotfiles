# Claude-Flow Configuration Suite

**Version:** 3.0
**Last Updated:** 2025-11-15

Complete configuration suite for Claude Code with Claude-Flow multi-agent orchestration and MCP tool integration.

---

## 📋 Overview

This configuration enables Claude Code to work as a powerful AI development assistant with:

- **Multi-agent orchestration** via Claude-Flow
- **6 MCP servers** for specialized capabilities
- **Concurrent execution patterns** for maximum efficiency
- **Memory and learning systems** for continuous improvement
- **Integrated workflows** combining research, documentation, implementation, and project management

---

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended)

```bash
# Run the setup script
./setup-test.sh

# Follow the prompts to create a test environment
# Default location: ~/test-claude-flow-app
```

### Option 2: Manual Setup

```bash
# 1. Create test directory
mkdir ~/my-test-project
cd ~/my-test-project

# 2. Copy configuration files
cp /path/to/CLAUDE.md .
cp -r /path/to/docs .

# 3. Initialize claude-flow
npx -y claude-flow@latest init --force

# 4. Verify setup
npx claude-flow@alpha status
claude mcp list
```

---

## 📦 What's Included

### Configuration Files

- **`CLAUDE.md`** - Main configuration for Claude Code AI Assistant
  - Tool execution hierarchy
  - Concurrent execution rules
  - File organization rules
  - Standard operating procedures
  - Integration patterns

### Documentation Files (`docs/`)

- **`claude-flow.md`** - Claude-Flow MCP native tools (80+ tools)
  - Swarm operations
  - Agent management
  - Task orchestration
  - Memory system
  - Neural operations
  - Performance monitoring

- **`context7.md`** - Official documentation retrieval
  - Library documentation lookup
  - API reference retrieval
  - Integration patterns

- **`googler.md`** - Web research and analysis
  - Google search
  - Content scraping
  - AI analysis with Gemini
  - Comprehensive research

- **`repomix.md`** - Codebase packaging and analysis
  - Repository packaging
  - Code search with regex
  - Architecture analysis
  - Security audits

- **`atl.md`** - Jira and Confluence management
  - Issue tracking
  - Sprint management
  - Documentation creation
  - Project coordination

- **`test-prompts.md`** - Test prompts and validation guide
  - 3 test levels (simple, complex, real-world)
  - Validation checklists
  - Success metrics
  - Troubleshooting guide

### Setup Script

- **`setup-test.sh`** - Automated setup script
  - Creates test directory
  - Copies all configuration files
  - Initializes claude-flow
  - Verifies MCP servers
  - Creates project structure
  - Initializes git repository

---

## 🔧 MCP Server Requirements

### Required Servers

```bash
# Claude-Flow (multi-agent orchestration)
claude mcp add claude-flow npx claude-flow@alpha mcp start

# Context7 (documentation retrieval)
# Installed via: npm install -g @upstash/context7-mcp

# Googler (web research)
# Custom installation required
```

### Optional Servers

```bash
# AgentDB (AI learning and memory)
# Installation required

# Repomix (codebase analysis)
claude mcp add repomix npx -y repomix --mcp

# ATL (Jira/Confluence)
# Installation: uvx --python python3.10 --with pydantic==2.11.0 mcp-atlassian -v
```

### Verify Installation

```bash
claude mcp list

# Expected output:
# claude-flow: ... - ✓ Connected
# context7: ... - ✓ Connected
# googler: ... - ✓ Connected
# agentdb: ... - ✓ Connected (optional)
# repomix: ... - ✓ Connected (optional)
# atl: ... - ✓ Connected (optional)
```

---

## 🎯 Testing the Configuration

### Step 1: Run Setup Script

```bash
./setup-test.sh
# Creates test environment at ~/test-claude-flow-app (default)
```

### Step 2: Navigate and Open

```bash
cd ~/test-claude-flow-app
claude code .
```

### Step 3: Use Test Prompt

Open `docs/test-prompts.md` and use **Level 1** test prompt:

```
Build a REST API authentication service with the following requirements:

REQUIREMENTS:
- Express.js backend with JWT authentication
- User registration and login endpoints
- Password hashing with bcrypt
- Input validation middleware
- Comprehensive test suite with Jest
- API documentation

USE ALL TOOLS:
- Googler: Research authentication patterns
- Context7: Get Express, JWT, bcrypt docs
- Claude-Flow: Coordinate multi-agent development
- AgentDB: Store learned patterns
- Task Tool: Spawn Backend, Test, and Documentation agents concurrently
```

### Step 4: Validate Results

Check the validation checklist in `docs/test-prompts.md`:

- [ ] All research/docs fetched in SAME message
- [ ] All agents spawned in SAME message
- [ ] TodoWrite called ONCE with 8+ todos
- [ ] Files organized in src/, tests/, docs/ (NOT root)
- [ ] Memory stored across namespaces
- [ ] AgentDB patterns recorded
- [ ] Hooks coordination between agents

---

## 📖 Key Features

### Concurrent Execution

**ALL operations must be batched in single messages:**

```javascript
// ✅ CORRECT - Single message with all operations
mcp__googler__research_topic({ query: "...", num_results: 3 })
mcp__context7__get-library-docs({ ... })
Task("Backend Dev", "...", "backend-dev")
Task("Test Engineer", "...", "tester")
TodoWrite({ todos: [...10 todos...] })
```

### Tool Hierarchy

1. **Task Tool (PRIMARY)** - Spawns real agents that execute work
2. **MCP Tools (COORDINATION)** - Research, docs, memory, learning
3. **NPX Subprocess (ORCHESTRATION)** - Multi-instance coordination

### File Organization

**NEVER save to root folder:**

```
✓ src/          - Source code
✓ tests/        - Test files
✓ docs/         - Documentation
✓ config/       - Configuration
✓ scripts/      - Utility scripts
✓ examples/     - Example code

✗ ROOT/         - Do not save working files here
```

### Memory Organization

**Namespaces for organized storage:**

```
project       - Project-wide context
architecture  - Architectural decisions
api           - API documentation
patterns      - Coding patterns
bugs          - Known issues and solutions
research      - Research findings
features      - Feature-specific knowledge
```

---

## 🔗 Integration Patterns

### Pattern: Complete Feature Development

```javascript
// 1. Analyze codebase (Repomix)
mcp__repomix__pack_codebase({ directory: "/path" })
mcp__repomix__grep_repomix_output({ pattern: "..." })

// 2. Research (Googler)
mcp__googler__research_topic({ query: "...", num_results: 3 })

// 3. Get docs (Context7)
mcp__context7__get-library-docs({ ... })

// 4. Create tasks (ATL)
mcp__atl__jira_create_issue({ ... })

// 5. Spawn agents (Task Tool - PRIMARY)
Task("Backend Dev", "...", "backend-dev")
Task("Test Engineer", "...", "tester")

// 6. Store knowledge (Claude-Flow + AgentDB)
mcp__claude-flow__memory_usage({ ... })
mcp__agentdb__reflexion_store({ ... })
```

See `docs/test-prompts.md` for 5 complete integration patterns.

---

## 📊 Performance Benefits

- **84.8% SWE-Bench solve rate**
- **32.3% token reduction** through concurrent execution
- **2.8-4.4x speed improvement** with parallel operations
- **27+ neural models** available in Claude-Flow
- **Continuous learning** via AgentDB pattern storage

---

## 🛠️ Troubleshooting

### MCP Servers Not Connected

```bash
# Check status
claude mcp list

# Reconnect
claude mcp add claude-flow npx claude-flow@alpha mcp start
```

### Claude-Flow Not Initialized

```bash
# Initialize
npx claude-flow@alpha init --force

# Verify
npx claude-flow@alpha status
```

### Memory Issues

```bash
# Check memory status
npx claude-flow@alpha memory status --reasoningbank

# List stored memories
npx claude-flow@alpha memory list --reasoningbank

# Query memory
npx claude-flow@alpha memory query "search term" --reasoningbank
```

### Files Created in Root

**Review prompt and ensure:**
- "NEVER save to root folder" is mentioned
- "Organize in /src, /tests, /docs" is specified
- CLAUDE.md file organization rules are active

---

## 📚 Resources

### Documentation
- **Main Config**: CLAUDE.md
- **Tool Guides**: docs/*.md
- **Test Prompts**: docs/test-prompts.md

### External Links
- Claude-Flow: https://github.com/ruvnet/claude-flow
- Claude-Flow Issues: https://github.com/ruvnet/claude-flow/issues
- Discord Community: https://discord.agentics.org

---

## 🤝 Contributing

This configuration suite is designed for LLM parsing optimization. When making changes:

1. Maintain imperative command structure (STEP, USE, IF/THEN)
2. Keep patterns in pseudo-code format
3. Preserve concurrent execution emphasis
4. Update all integration examples
5. Test with validation checklist

---

## 📝 Version History

### 3.0 (2025-11-15)
- Added Repomix MCP integration
- Added ATL (Jira/Confluence) MCP integration
- Created 5 advanced integration patterns
- Added automated setup script
- Comprehensive test prompts with 3 levels
- LLM-optimized documentation structure

### 2.0
- Added Context7 and Googler MCP integration
- Integrated AgentDB for AI learning
- Enhanced concurrent execution patterns

### 1.0
- Initial Claude-Flow configuration
- Basic MCP integration

---

**🎯 Ready to test? Run `./setup-test.sh` to get started!**

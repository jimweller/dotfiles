# Test Prompts for CLAUDE.md Configuration

**Purpose:** Test prompts to verify the complete MCP integration suite
**Last Updated:** 2025-11-15

---

## 🎯 SETUP INSTRUCTIONS

### Step 1: Copy Configuration Files

```bash
# Create new test directory
mkdir -p ~/test-claude-flow-app

# Copy configuration files
cp /path/to/CLAUDE.md ~/test-claude-flow-app/
cp -r /path/to/docs ~/test-claude-flow-app/

# Navigate to new directory
cd ~/test-claude-flow-app
```

### Step 2: Verify MCP Servers

```bash
# Check all MCP servers are connected
claude mcp list

# Should show:
# - claude-flow ✓
# - context7 ✓
# - googler ✓
# - agentdb ✓
# - repomix ✓
# - atl ✓ (optional)
```

### Step 3: Initialize Claude-Flow

```bash
# Initialize in the new directory
npx -y claude-flow@latest init --force

# Verify initialization
npx claude-flow@alpha status
```

---

## 🚀 TEST PROMPTS

### Level 1: Simple Feature Test (Validates Basic Integration)

**Prompt:**

```
Build a REST API authentication service with the following requirements:

REQUIREMENTS:
- Express.js backend with JWT authentication
- User registration and login endpoints
- Password hashing with bcrypt
- Input validation middleware
- Comprehensive test suite with Jest
- API documentation

WORKFLOW:
1. Research current authentication best practices
2. Get official Express.js and JWT library documentation
3. Implement the authentication service
4. Write comprehensive tests
5. Store implementation patterns for future learning

USE ALL TOOLS:
- Googler: Research authentication patterns
- Context7: Get Express, JWT, bcrypt docs
- Claude-Flow: Coordinate multi-agent development
- AgentDB: Store learned patterns
- Task Tool: Spawn Backend, Test, and Documentation agents concurrently

DELIVERABLES:
- Working authentication API
- Test suite with >80% coverage
- API documentation
- Stored knowledge in memory for future reference
```

**Expected Behavior:**
- ✅ Googler researches authentication best practices 2024
- ✅ Context7 fetches Express.js, jsonwebtoken, bcrypt docs
- ✅ Claude-Flow initializes hierarchical swarm
- ✅ Task Tool spawns 3+ agents concurrently (backend-dev, tester, documenter)
- ✅ Files organized in src/, tests/, docs/ (NOT root)
- ✅ TodoWrite batches 8-10 todos in single call
- ✅ Memory stores implementation patterns
- ✅ AgentDB records successful patterns

---

### Level 2: Complex Application Test (Validates Full Integration)

**Prompt:**

```
Build a complete microservices-based task management system with the following architecture:

PROJECT: TaskFlow - Microservices Task Management Platform

ARCHITECTURE:
- API Gateway (Express.js)
- Authentication Service (JWT + OAuth2)
- Task Service (CRUD operations)
- Notification Service (WebSocket + Email)
- PostgreSQL database with Prisma ORM
- Redis for caching and sessions
- Docker containerization
- Full test coverage

WORKFLOW REQUIREMENTS:
1. ANALYZE: Check if similar patterns exist in any example repositories
2. RESEARCH: Best practices for microservices architecture 2024
3. DOCUMENTATION: Get official docs for all libraries (Express, Prisma, Redis, Socket.io)
4. ARCHITECTURE: Design system architecture and document in Confluence (if ATL available)
5. IMPLEMENTATION: Build all services concurrently using swarm coordination
6. TESTING: Comprehensive unit, integration, and e2e tests
7. LEARNING: Store all patterns and architectural decisions

USE ALL AVAILABLE TOOLS:
- Repomix: Analyze any relevant existing codebases for patterns
- Googler: Research microservices best practices, Docker patterns
- Context7: Get official documentation for Express, Prisma, Redis, Socket.io, Jest
- ATL (if available): Create Jira epic with tasks, document architecture in Confluence
- Claude-Flow: Initialize mesh topology for complex coordination
- AgentDB: Store architectural patterns and implementation learnings
- Task Tool: Spawn multiple specialized agents (architect, backend-dev, db-architect, test-engineer, devops-engineer)

CONCURRENT EXECUTION REQUIREMENTS:
- ALL research and documentation fetching in SINGLE message
- ALL agent spawning in SINGLE message
- ALL file operations batched
- TodoWrite with 10+ tasks minimum
- Memory operations batched by namespace

DELIVERABLES:
- Complete microservices architecture
- All services in separate directories
- Docker Compose configuration
- Comprehensive test suite
- API documentation
- Architecture documentation (Confluence if ATL available)
- Stored knowledge in memory across namespaces (architecture, api, patterns)
- AgentDB patterns for future microservices projects
```

**Expected Behavior:**
- ✅ Repomix packs any relevant repos (if provided)
- ✅ Googler researches microservices + Docker + testing patterns (3-4 sources)
- ✅ Context7 fetches docs for 5+ libraries in parallel
- ✅ ATL creates Jira epic + tasks, Confluence architecture doc (if available)
- ✅ Claude-Flow initializes mesh topology with 8+ agents
- ✅ Task Tool spawns 6+ agents concurrently in single message
- ✅ Files organized: /services/auth, /services/tasks, /services/notifications, /tests, /docs
- ✅ TodoWrite batches 15+ todos covering all phases
- ✅ Memory stores across multiple namespaces (architecture, api, patterns, services)
- ✅ AgentDB stores architectural patterns, implementation patterns, testing patterns
- ✅ Hooks coordinate between agents (pre-task, post-edit, post-task)

---

### Level 3: Real-World Complex System (Ultimate Integration Test)

**Prompt:**

```
I need to build a production-ready SaaS platform for team collaboration. This is a multi-week project requiring comprehensive planning and execution.

PROJECT: CollabHub - Enterprise Team Collaboration Platform

BUSINESS REQUIREMENTS:
- Multi-tenant SaaS architecture with organization/workspace isolation
- Real-time collaboration (documents, chat, video calls)
- Role-based access control (RBAC) with permissions
- Payment integration (Stripe subscriptions)
- File storage and sharing (AWS S3 + CDN)
- Search functionality (Elasticsearch)
- Analytics and reporting dashboard
- Mobile-responsive web app (React + TypeScript)
- Admin panel for platform management
- Email notifications and in-app notifications
- Audit logging for compliance
- API for third-party integrations

TECHNICAL STACK RESEARCH REQUIRED:
- Backend: Node.js framework selection (NestJS vs Express vs Fastify)
- Frontend: React framework (Next.js vs Vite vs CRA)
- Database: PostgreSQL + Redis + Elasticsearch
- Real-time: WebSocket vs WebRTC vs third-party (Socket.io, Pusher, Agora)
- Payment: Stripe integration patterns
- Auth: JWT + OAuth2 + SSO (Auth0 vs custom)
- File Storage: AWS S3 + CloudFront
- Containerization: Docker + Kubernetes

PHASE 1: PLANNING & RESEARCH (Current Phase)
1. Analyze existing SaaS architectures in popular repos (Repomix)
2. Research best practices for multi-tenant architecture (Googler)
3. Research real-time collaboration patterns (Googler)
4. Get official documentation for candidate technologies (Context7)
5. Create Jira epic with detailed task breakdown (ATL if available)
6. Document architecture decisions in Confluence (ATL if available)
7. Create project structure and initial configuration
8. Set up development environment

REQUIRED TOOL USAGE:
- Repomix: Analyze 2-3 open-source SaaS platforms for architectural patterns
- Googler: Research multi-tenant SaaS, real-time collaboration, payment integration, RBAC patterns
- Context7: Fetch docs for 10+ libraries (NestJS, Next.js, Prisma, Stripe, Socket.io, etc.)
- ATL: Create comprehensive Jira epic with 50+ tasks across multiple sprints, create Confluence space with architecture documentation
- Claude-Flow: Initialize hierarchical topology, spawn Hive-Mind for multi-week project
- AgentDB: Store all architectural decisions, patterns, and learnings
- Task Tool: Spawn specialized agents (system-architect, researcher, backend-dev, frontend-dev, devops-engineer, security-auditor, tech-lead)

EXECUTION REQUIREMENTS:
- Initialize Hive-Mind session for long-term project tracking
- ALL tool calls for research/docs in first message batch
- Spawn 8+ specialized agents concurrently
- Create comprehensive project structure: /backend, /frontend, /shared, /infrastructure, /docs, /tests
- TodoWrite with 20+ high-level tasks
- Memory organized in namespaces: architecture, backend, frontend, infrastructure, security, api, integrations
- AgentDB stores: architectural_patterns, saas_patterns, realtime_patterns, payment_patterns, auth_patterns

DELIVERABLES FOR PHASE 1:
- Technology selection with justification
- Complete architecture documentation (Confluence if available)
- Jira epic with detailed sprint planning (ATL if available)
- Project structure with initial configuration
- Development environment setup (Docker Compose)
- Core libraries installed and configured
- Initial CI/CD pipeline configuration
- Security baseline configuration
- Database schema design
- API contract definitions
- Stored knowledge for subsequent phases

OUTPUT REQUIREMENTS:
- Provide architecture decision rationale for each technology choice
- Show how all tools were used in coordination
- Demonstrate concurrent execution patterns
- Explain memory organization strategy
- Show AgentDB learning patterns stored
```

**Expected Behavior:**
- ✅ Repomix analyzes 2-3 GitHub repos for SaaS patterns
- ✅ Googler performs 5+ research queries (multi-tenant, real-time, payments, auth, RBAC)
- ✅ Context7 fetches 10+ library documentation sets in parallel
- ✅ ATL creates Jira epic with 50+ tasks, Confluence space with architecture docs
- ✅ Claude-Flow spawns Hive-Mind session for multi-week tracking
- ✅ Task Tool spawns 8+ specialized agents in single message
- ✅ Creates comprehensive directory structure (backend/, frontend/, infrastructure/, etc.)
- ✅ TodoWrite batches 20+ strategic tasks
- ✅ Memory stores across 7+ namespaces
- ✅ AgentDB stores 5+ pattern categories
- ✅ Demonstrates hooks coordination between agents
- ✅ Shows session management for resumable work

---

## 🧪 VALIDATION CHECKLIST

### After Running Test Prompt

**Verify Concurrent Execution:**
- [ ] All research/doc fetching happened in SAME message
- [ ] All agents spawned in SAME message
- [ ] TodoWrite called ONCE with 8+ todos
- [ ] File operations batched together
- [ ] Memory operations batched by namespace

**Verify Tool Integration:**
- [ ] Googler: Research queries executed
- [ ] Context7: Library docs fetched
- [ ] Repomix: Codebases analyzed (if applicable)
- [ ] ATL: Jira/Confluence operations (if available)
- [ ] Claude-Flow: Swarm/Hive-Mind initialized
- [ ] AgentDB: Patterns stored
- [ ] Task Tool: Agents spawned (PRIMARY execution)

**Verify File Organization:**
- [ ] NO files in root directory (except CLAUDE.md, package.json, etc.)
- [ ] Source files in /src or /services
- [ ] Tests in /tests
- [ ] Docs in /docs
- [ ] Config in /config

**Verify Memory & Learning:**
- [ ] Memory stored in appropriate namespaces
- [ ] AgentDB patterns recorded
- [ ] Hooks executed (check output for hook calls)
- [ ] Session created for resumable work

**Verify Code Quality:**
- [ ] Working implementation
- [ ] Tests pass (if tests written)
- [ ] Code follows best practices from research
- [ ] Documentation generated

---

## 🔍 TROUBLESHOOTING

### If Tools Not Used

**Check CLAUDE.md is in directory:**
```bash
ls -la CLAUDE.md docs/
```

**Check MCP servers connected:**
```bash
claude mcp list
```

**Verify claude-flow initialized:**
```bash
npx claude-flow@alpha status
```

### If Execution Not Concurrent

**Check prompt explicitly states:**
- "in SINGLE message"
- "ALL operations together"
- "batch ALL todos"
- "spawn ALL agents concurrently"

### If Files in Root

**Reminder in prompt:**
- "NEVER save to root folder"
- "Organize in /src, /tests, /docs"
- "Follow file organization rules"

---

## 📊 SUCCESS METRICS

### Level 1 (Simple Feature)
- ✅ 3+ MCP tools used
- ✅ 3+ agents spawned
- ✅ Files organized correctly
- ✅ Tests pass
- ✅ Memory stored

### Level 2 (Complex Application)
- ✅ 5+ MCP tools used
- ✅ 6+ agents spawned
- ✅ Microservices architecture
- ✅ Docker configuration
- ✅ Multiple namespaces used
- ✅ AgentDB patterns stored

### Level 3 (Real-World System)
- ✅ ALL MCP tools used
- ✅ 8+ agents spawned
- ✅ Hive-Mind session created
- ✅ Comprehensive architecture
- ✅ 7+ memory namespaces
- ✅ 5+ AgentDB pattern categories
- ✅ Production-ready configuration

---

## 💡 TIPS FOR BEST RESULTS

### Prompt Engineering
```
GOOD PROMPT ELEMENTS:
- Explicit tool mentions: "USE Googler to research..."
- Concurrent execution: "in SINGLE message"
- File organization: "organize in /src, /tests, /docs"
- Memory namespaces: "store in architecture namespace"
- Agent types: "spawn backend-dev, tester, documenter agents"

AVOID:
- Vague requests: "build an app"
- No tool guidance: assuming Claude will auto-select
- Sequential language: "first do X, then do Y"
- Root file mentions: "create README.md" (should be /docs/README.md)
```

### Verification
```
AFTER EXECUTION:
1. Check file structure: ls -R
2. Check memory: npx claude-flow@alpha memory list --reasoningbank
3. Check AgentDB: Look for pattern storage confirmations
4. Check git history: git log (if initialized)
5. Run tests: npm test (if created)
```

---

## 🎯 RECOMMENDED TEST SEQUENCE

1. **Start with Level 1** (Simple Feature)
   - Validates basic integration
   - ~5-10 minutes
   - Good for verifying setup

2. **Move to Level 2** (Complex Application)
   - Validates full integration
   - ~15-30 minutes
   - Tests concurrent coordination

3. **Try Level 3** (Real-World System)
   - Validates production readiness
   - ~30-60 minutes for Phase 1
   - Multi-session capability

---

**Last Updated:** 2025-11-15
**Configuration Version:** 3.0

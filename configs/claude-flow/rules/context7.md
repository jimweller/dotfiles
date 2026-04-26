# Context7 MCP - Official Documentation Retrieval

**Target:** LLM execution
**Purpose:** Retrieve up-to-date official documentation for libraries, APIs, SDKs
**Last Updated:** 2025-11-15

---

## TOOL INVOCATION

### resolve-library-id

````text
mcp__context7__resolve-library-id({ libraryName: string })
```text

**Purpose:** Convert library/package name to Context7-compatible ID
**Required:** YES (unless user provides ID in `/org/project` format)
**Returns:** Library ID, description, benchmark score, reputation

**Parameters:**

- `libraryName` (required): Library name (e.g., "react", "stripe", "next.js")

**Selection Criteria (when multiple matches):**

1. Name similarity (exact match prioritized)
2. Description relevance to query context
3. Documentation coverage (Code Snippet count)
4. Source reputation (High/Medium > Low)
5. Benchmark score (100 = highest)

### get-library-docs

```text
mcp__context7__get-library-docs({
  context7CompatibleLibraryID: string,
  topic?: string,
  tokens?: number
})
```text

**Purpose:** Fetch documentation content
**Required:** Must use resolved ID from previous call
**Returns:** Documentation in markdown format

**Parameters:**

- `context7CompatibleLibraryID` (required): ID from resolve-library-id (format: `/org/project` or `/org/project/version`)
- `topic` (optional): Specific topic filter (e.g., "hooks", "authentication", "API")
- `tokens` (optional): Max tokens (default: 5000, range: 1000-15000)

---

## EXECUTION PATTERNS

### Pattern: Basic Documentation Lookup

```text
STEP 1: mcp__context7__resolve-library-id({ libraryName: "stripe" })
RETURNS: /stripe/stripe-node

STEP 2: mcp__context7__get-library-docs({
  context7CompatibleLibraryID: "/stripe/stripe-node",
  topic: "webhooks"
})
```text

### Pattern: Specific Version

```text
STEP 1: mcp__context7__resolve-library-id({ libraryName: "next.js 14" })
RETURNS: /vercel/next.js/v14.0.0

STEP 2: mcp__context7__get-library-docs({
  context7CompatibleLibraryID: "/vercel/next.js/v14.0.0",
  topic: "app router"
})
```text

### Pattern: Comprehensive API Reference

```text
STEP 1: mcp__context7__resolve-library-id({ libraryName: "supabase" })
RETURNS: /supabase/supabase

STEP 2: mcp__context7__get-library-docs({
  context7CompatibleLibraryID: "/supabase/supabase",
  topic: "authentication API",
  tokens: 10000
})
```text

### Pattern: User Provides Exact ID

```text
SKIP STEP 1

STEP 2: mcp__context7__get-library-docs({
  context7CompatibleLibraryID: "/mongodb/docs",
  topic: "aggregation"
})
```text

---

## WHEN TO USE

```text
USE Context7 FOR:
  ✅ Official library/framework documentation
  ✅ API reference documentation
  ✅ SDK usage patterns
  ✅ Integration examples
  ✅ Up-to-date syntax (handles breaking changes)
  ✅ Code examples from official sources

DO NOT USE FOR:
  ❌ General web search (use Googler)
  ❌ Best practices articles (use Googler)
  ❌ Community tutorials (use Googler)
  ❌ Code in current project (use file tools)
  ❌ Comparisons between libraries (use Googler)
```text

---

## COMMON LIBRARIES

### Frontend Frameworks

```text
react           → /facebook/react
next.js         → /vercel/next.js
vue             → /vuejs/core
svelte          → /sveltejs/svelte
angular         → /angular/angular
```text

### Backend & APIs

```text
express         → /expressjs/express
fastify         → /fastify/fastify
nestjs          → /nestjs/nest
koa             → /koajs/koa
hapi            → /hapijs/hapi
```text

### Databases & ORMs

```text
mongodb         → /mongodb/docs
prisma          → /prisma/prisma
supabase        → /supabase/supabase
typeorm         → /typeorm/typeorm
sequelize       → /sequelize/sequelize
```text

### Payment & Auth

```text
stripe          → /stripe/stripe-node
auth0           → /auth0/node-auth0
firebase        → /firebase/firebase-js-sdk
clerk           → /clerk/javascript
```text

### Testing

```text
jest            → /jestjs/jest
vitest          → /vitest-dev/vitest
playwright      → /microsoft/playwright
cypress         → /cypress-io/cypress
```text

---

## TOKEN OPTIMIZATION

### Token Allocation

```text
Quick reference:     5000 tokens (default)
Standard lookup:     5000-8000 tokens
Comprehensive API:   8000-10000 tokens
Deep dive:           10000-15000 tokens
```text

### Topic Specificity Impact

```text
NO topic parameter:     Broad, unfocused (use more tokens)
WITH specific topic:    Focused, efficient (use fewer tokens)
```text

**Recommendation:** Always use `topic` parameter for token efficiency

---

## ERROR HANDLING

### Multiple Matches

```text
IF resolve-library-id returns multiple options:
  ANALYZE: name similarity, description, benchmark score
  SELECT: best match based on criteria
  IF ambiguous:
    ASK user to clarify OR
    DEFAULT to highest benchmark score + best name match
```text

### No Matches

```text
IF resolve-library-id returns no results:
  1. CHECK spelling of libraryName
  2. TRY alternative names (e.g., "@package/name" vs "package")
  3. FALLBACK: mcp__googler__research_topic for general info
  4. INFORM user: library may be too new/obscure for Context7
```text

### Invalid Library ID

```text
IF get-library-docs fails with provided ID:
  1. VERIFY ID format (/org/project or /org/project/version)
  2. RE-RUN resolve-library-id to get correct ID
  3. RETRY get-library-docs with corrected ID
```text

### User Ambiguity

```text
SCENARIO: "How do I format dates?"
PROBLEM: Multiple libraries (date-fns, dayjs, luxon, moment)

RESPONSE OPTIONS:
  Option 1: ASK user which library
  Option 2: DEFAULT to most popular (date-fns)
  Option 3: PROVIDE brief comparison first
```text

---

## INTEGRATION PATTERNS

### With Claude-Flow Memory

```text
1. mcp__context7__resolve-library-id({ libraryName: "stripe" })
2. mcp__context7__get-library-docs({
     context7CompatibleLibraryID: "/stripe/stripe-node",
     topic: "payment intents"
   })
3. mcp__claude-flow__memory_usage({
     action: "store",
     key: "stripe_payment_intents",
     value: "documentation_summary",
     namespace: "research"
   })
```text

### With Googler Research

```text
1. mcp__googler__research_topic({
     query: "stripe payment best practices 2024",
     num_results: 3
   })
2. mcp__context7__resolve-library-id({ libraryName: "stripe" })
3. mcp__context7__get-library-docs({
     context7CompatibleLibraryID: "/stripe/stripe-node"
   })
4. SYNTHESIZE: best practices + official docs
5. mcp__claude-flow__memory_usage({ action: "store", namespace: "research" })
```text

### Combined Documentation Strategy

```text
FOR implementation task:
  STEP 1: Get official API docs (Context7)
  STEP 2: Get real-world examples (Googler)
  STEP 3: Store combined knowledge (Claude-Flow)
  STEP 4: Implement feature
```text

---

## QUERY OPTIMIZATION

### Effective Topic Filters

```text
GOOD topic parameters:
  ✅ "authentication"
  ✅ "useEffect hook"
  ✅ "webhooks"
  ✅ "API routes"
  ✅ "database migrations"

POOR topic parameters:
  ❌ "everything"
  ❌ "docs"
  ❌ "help"
  ❌ "usage"
```text

### LibraryName Best Practices

```text
SPECIFIC:
  ✅ "next.js 14"
  ✅ "@stripe/stripe-js"
  ✅ "react-query"

GENERIC (may need disambiguation):
  ⚠️ "react"
  ⚠️ "node"
  ⚠️ "express"
```text

---

## DECISION TREE

```text
START
  |
  ├─ Need official API docs? → YES → Context7
  |
  ├─ Need best practices? → YES → Googler
  |
  ├─ Need library comparison? → YES → Googler
  |
  ├─ Need real-world examples? → YES → Googler
  |
  └─ Need code in this project? → YES → File tools

Context7 Path:
  1. resolve-library-id (unless ID provided)
  2. get-library-docs (with topic if possible)
  3. Store results if needed
```text

---

## PERFORMANCE OPTIMIZATION

### Minimize Tool Calls

```text
EFFICIENT:
  - Resolve once, fetch multiple topics sequentially if needed
  - Use specific topic parameter
  - Cache/store frequently accessed docs

INEFFICIENT:
  - Resolve same library multiple times
  - Fetch docs without topic filter
  - Re-fetch same docs repeatedly
```text

### Token Management

```text
START low (5000 tokens)
IF insufficient:
  INCREASE to 8000-10000
IF still insufficient:
  SPLIT into multiple queries with different topics
```text

---

## QUICK REFERENCE

```text
TOOLS:
  mcp__context7__resolve-library-id({ libraryName })
  mcp__context7__get-library-docs({ context7CompatibleLibraryID, topic?, tokens? })

WORKFLOW:
  1. Resolve library ID (unless provided)
  2. Fetch docs with specific topic
  3. Store in memory if needed

WHEN TO USE:
  Official docs, API references, SDK usage

WHEN NOT TO USE:
  General search, best practices, comparisons, tutorials
```text

---

**MCP Server:** context7
**Status:** Connected
**Provider:** @upstash/context7-mcp
**Optimized for:** LLM direct execution
````

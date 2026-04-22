# Googler MCP - Web Research & AI Analysis

**Target:** LLM execution
**Purpose:** Web research, content scraping, AI analysis, comprehensive topic investigation
**Last Updated:** 2025-11-15

---

## TOOL INVOCATION

### google_search

```text
mcp__googler__google_search({
  query: string,
  num_results?: number  // 1-10, default: 5
})
```text

**Purpose:** Search Google, retrieve results with summaries
**Returns:** Array of {title, url, snippet}

**Parameters:**

- `query` (required): Search query string
- `num_results` (optional): Result count (1-10, default: 5)

**Best Query Patterns:**

- Include year: "react 18 features 2024"
- Use comparisons: "stripe vs paypal pros cons"
- Technical terms: "JWT authentication best practices Node.js"
- Specific problems: "PostgreSQL connection pool exhaustion solution"

### scrape_page

```text
mcp__googler__scrape_page({
  url: string
})
```text

**Purpose:** Extract content from URL (web pages or YouTube videos)
**Returns:** Content in markdown format

**Parameters:**

- `url` (required): HTTP/HTTPS URL or YouTube URL

**Supported:**

- Web articles, blog posts
- Technical documentation sites
- YouTube videos (auto-extracts transcript)
- GitHub README files
- Tutorial websites

### analyze_with_gemini

```text
mcp__googler__analyze_with_gemini({
  text: string,
  model?: string  // default: "gemini-2.0-flash-001"
})
```text

**Purpose:** AI analysis of text content
**Returns:** Analysis summary, insights, key points

**Parameters:**

- `text` (required): Content to analyze
- `model` (optional): "gemini-2.0-flash-001" (fast) | "gemini-pro" (detailed)

**Use Cases:**

- Summarize long articles
- Extract key points
- Compare technical approaches
- Identify pros/cons
- Technical analysis

### research_topic

```text
mcp__googler__research_topic({
  query: string,
  num_results?: number  // 1-5, default: 3
})
```text

**Purpose:** Comprehensive all-in-one research (search + scrape + analyze)
**Returns:** Synthesized analysis from multiple sources

**Parameters:**

- `query` (required): Research topic or question
- `num_results` (optional): Sources to analyze (1-5, default: 3)

**What It Does:**

1. Searches Google for top results
2. Scrapes content from each source
3. Analyzes all content with Gemini
4. Returns synthesized insights

**Best For:**

- Architecture decisions
- Technology comparisons
- Best practices research
- Trend analysis
- Comprehensive overviews

---

## EXECUTION PATTERNS

### Pattern: Quick Search & Review

```text
STEP 1: mcp__googler__google_search({
  query: "React 18 new features 2024",
  num_results: 5
})

STEP 2: SELECT best URL from results

STEP 3: mcp__googler__scrape_page({ url: "selected_url" })
```text

### Pattern: Deep Article Analysis

```text
STEP 1: mcp__googler__scrape_page({ url: "article_url" })

STEP 2: mcp__googler__analyze_with_gemini({
  text: "scraped_content",
  model: "gemini-pro"
})
```text

### Pattern: Comprehensive Research (Recommended)

```text
SINGLE CALL: mcp__googler__research_topic({
  query: "microservices vs monolithic architecture pros cons 2024",
  num_results: 4
})

RETURNS: Multi-source synthesis
```text

### Pattern: YouTube Tutorial Research

```text
STEP 1: mcp__googler__google_search({
  query: "Next.js App Router tutorial site:youtube.com",
  num_results: 3
})

STEP 2: mcp__googler__scrape_page({
  url: "youtube_video_url"
})

STEP 3: mcp__googler__analyze_with_gemini({
  text: "transcript_content"
})
```text

### Pattern: Competitive Analysis

```text
mcp__googler__research_topic({
  query: "Stripe vs Braintree vs PayPal comparison features pricing 2024",
  num_results: 5
})
```text

---

## WHEN TO USE

```text
USE Googler FOR:
  ✅ Web research on technical topics, trends
  ✅ Article analysis and summarization
  ✅ YouTube transcript extraction
  ✅ Competitive analysis
  ✅ Latest information not in training data
  ✅ Real-world examples, case studies
  ✅ Technical blog posts, tutorials
  ✅ Best practices articles
  ✅ Technology comparisons

DO NOT USE FOR:
  ❌ Official API documentation (use Context7)
  ❌ Code in current project (use file tools)
  ❌ Library SDK references (use Context7)
```text

---

## SEARCH QUERY PATTERNS

### Architecture Research

```text
Pattern: "[tech1] vs [tech2] [aspect] [year]"
Example: "GraphQL vs REST API performance scalability 2024"
```text

### Best Practices

```text
Pattern: "[technology] best practices [area] [year]"
Example: "Node.js error handling best practices production 2024"
```text

### Technical Comparisons

```text
Pattern: "[opt1] vs [opt2] vs [opt3] comparison"
Example: "Docker vs Kubernetes vs AWS ECS container orchestration comparison"
```text

### Problem Solving

```text
Pattern: "how to [problem] [technology] [year]"
Example: "how to implement rate limiting Express.js Redis 2024"
```text

### Trend Analysis

```text
Pattern: "[technology] trends [year]"
Example: "web development frameworks trends 2024"
```text

### Security Research

```text
Pattern: "[technology] security vulnerabilities [year]"
Example: "JWT authentication security vulnerabilities best practices 2024"
```text

---

## NUM_RESULTS OPTIMIZATION

### google_search

```text
Quick check:        3-5 results
Comprehensive:      8-10 results

Trade-off: More results = more options, but slower
```text

### research_topic

```text
Quick overview:     2-3 sources (faster, cheaper)
Standard research:  3-4 sources (balanced)
Deep research:      4-5 sources (comprehensive, expensive)

Trade-off: More sources = better synthesis, but higher token cost
```text

---

## MODEL SELECTION

### Gemini Models

```text
gemini-2.0-flash-001:
  - Speed: Fast
  - Cost: Lower
  - Use: Quick summaries, standard analysis
  - DEFAULT

gemini-pro:
  - Speed: Slower
  - Cost: Higher
  - Use: Detailed analysis, complex synthesis
  - SELECTIVE USE
```text

---

## ERROR HANDLING

### Network/Access Issues

```text
IF scrape_page fails:
  1. CHECK URL validity
  2. TRY alternative source from search results
  3. INFORM user: site may block automated access
```text

### No Relevant Results

```text
IF google_search returns poor results:
  1. REFINE query with more specific terms
  2. ADD year for recency
  3. INCLUDE comparison/evaluation terms
  4. TRY alternative search terms
```text

### YouTube Transcript Unavailable

```text
IF scrape_page fails on YouTube URL:
  1. INFORM user: transcript not available
  2. SEARCH for alternative videos
  3. FALLBACK to written tutorials
```text

---

## INTEGRATION PATTERNS

### With Context7

```text
STEP 1: mcp__googler__research_topic({
  query: "payment processing best practices 2024",
  num_results: 3
})

STEP 2: mcp__context7__resolve-library-id({ libraryName: "stripe" })

STEP 3: mcp__context7__get-library-docs({
  context7CompatibleLibraryID: "/stripe/stripe-node"
})

STEP 4: SYNTHESIZE: best practices + official docs

STEP 5: mcp__claude-flow__memory_usage({
  action: "store",
  namespace: "research"
})
```text

### With Claude-Flow Memory

```text
STEP 1: mcp__googler__research_topic({
  query: "database comparison PostgreSQL MongoDB Redis 2024",
  num_results: 4
})

STEP 2: mcp__claude-flow__memory_usage({
  action: "store",
  key: "database_research",
  value: "synthesized_findings",
  namespace: "research"
})
```text

### Combined Research Workflow

```text
FOR implementation task:
  1. Research best practices (Googler)
  2. Get official docs (Context7)
  3. Store combined knowledge (Claude-Flow)
  4. Implement feature
```text

---

## QUERY OPTIMIZATION

### Effective Queries

```text
GOOD:
  ✅ "JWT authentication best practices Node.js 2024"
  ✅ "Stripe vs PayPal comparison pros cons"
  ✅ "microservices communication patterns gRPC REST"
  ✅ "PostgreSQL connection pool exhaustion solution"

POOR:
  ❌ "authentication"
  ❌ "payments"
  ❌ "database"
  ❌ "help"
```text

### Query Enhancement

```text
ADD specificity:
  "payments" → "stripe payment integration best practices"

ADD recency:
  "react features" → "react 18 features 2024"

ADD comparison:
  "databases" → "PostgreSQL vs MongoDB comparison 2024"

ADD technology context:
  "caching" → "Redis caching strategies Node.js"
```text

---

## PERFORMANCE OPTIMIZATION

### Token Efficiency

```text
research_topic with 2-3 sources:
  - Faster
  - Lower cost
  - Sufficient for most tasks

research_topic with 4-5 sources:
  - Slower
  - Higher cost
  - Better for complex decisions
```text

### Model Efficiency

```text
gemini-2.0-flash-001 (default):
  - Use for: Most analysis tasks
  - Speed: Fast
  - Cost: Lower

gemini-pro (selective):
  - Use for: Critical decisions, complex synthesis
  - Speed: Slower
  - Cost: Higher
```text

### Minimize Redundant Calls

```text
EFFICIENT:
  - Use research_topic (all-in-one) for comprehensive needs
  - Cache/store research results
  - Reuse scraped content for multiple analyses

INEFFICIENT:
  - Manual search → scrape → analyze for each source
  - Re-scraping same URLs
  - Re-analyzing same content
```text

---

## DECISION TREE

```text
START
  |
  ├─ Need comprehensive multi-source research?
  |  → YES → research_topic (recommended)
  |
  ├─ Need to analyze specific URL?
  |  → YES → scrape_page → analyze_with_gemini
  |
  ├─ Need to find sources first?
  |  → YES → google_search → select URL → scrape_page
  |
  └─ Need YouTube tutorial?
     → YES → google_search (site:youtube.com) → scrape_page
```text

---

## USE CASE EXAMPLES

### Technology Selection

```text
mcp__googler__research_topic({
  query: "message queue comparison RabbitMQ Kafka Redis Streams 2024",
  num_results: 4
})

THEN: Store decision in Claude-Flow memory
```text

### Best Practices Implementation

```text
mcp__googler__research_topic({
  query: "Node.js API rate limiting best practices Redis implementation",
  num_results: 3
})

THEN: Get official library docs (Context7)
THEN: Implement with combined knowledge
```text

### Troubleshooting

```text
mcp__googler__google_search({
  query: "PostgreSQL connection pool exhaustion Node.js solution",
  num_results: 5
})

THEN: Scrape best solution article
THEN: Store in bugs namespace
```text

---

## QUICK REFERENCE

```text
TOOLS:
  mcp__googler__google_search({ query, num_results? })
  mcp__googler__scrape_page({ url })
  mcp__googler__analyze_with_gemini({ text, model? })
  mcp__googler__research_topic({ query, num_results? })

RECOMMENDED:
  research_topic - All-in-one comprehensive research

WHEN TO USE:
  Best practices, comparisons, trends, examples, tutorials

WHEN NOT TO USE:
  Official docs (use Context7), code in project (use file tools)

QUERY TIPS:
  - Include year for recency
  - Use comparison keywords
  - Be specific with technology names
  - Add context (Node.js, production, etc.)
```text

---

**MCP Server:** googler
**Status:** Connected
**Provider:** github:jimweller/google-research-mcp
**Optimized for:** LLM direct execution

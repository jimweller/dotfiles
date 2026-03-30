---
name: sage
argument-hint: "<library or topic to research>"
description: This skill should be used when the user asks to "research", "look up docs", "check the latest documentation", "find best practices", "google this", "web search", "what does the documentation say", "is this still current", or mentions needing up-to-date information about a library, framework, CLI tool, API, or cloud service.
---

STARTER_CHARACTER = 🧑‍🎓

# Sage

Research skill using c7 (Context7) and g (Google) MCP servers to fetch current documentation and best practices. Never present training data as current when this skill is active. Always verify via c7 or g first.

---

## Decision Logic

1. If the question targets a specific library, framework, SDK, API, or CLI tool: use c7 first
2. If the question is about best practices, patterns, comparisons, troubleshooting, or general topics: use c7 and g
3. For complex research spanning multiple queries: use `sequential_search` to track state

---

## c7: Library Documentation

c7 indexes official documentation. Always current. No date filtering needed.

### Workflow

1. Resolve the library ID:

```
mcp__c7__resolve-library-id
  libraryName: "<library name>"
  query: "<specific question>"
```

2. Pick the best match: highest benchmark score + source reputation. Prefer `High` reputation.

3. Query the docs:

```
mcp__c7__query-docs
  libraryId: "<resolved ID>"
  query: "<specific question>"
```

### c7 Rules

- If `resolve-library-id` returns no matches, fall back to g
- When multiple libraries match, pick by: name match first, then benchmark score, then source reputation
- Be specific in queries: "How to set up JWT authentication in Express.js" not "auth"

---

## g: Web Research

For broader questions, best practices, comparisons, or when c7 has no coverage.

### Date Bias

Google queries must append the current year and the prior year to bias toward recent results. Example:

```
"terraform aws provider best practices 2025 2026"
"next.js app router migration guide 2025 2026"
```

This applies to all `query` fields sent to g tools.

### Tool Selection

**`search_and_scrape` (preferred)** -- search + retrieve content in one call:

```
mcp__g__search_and_scrape
  query: "<topic> <current_year> <prior_year>"
  num_results: 3-5
```

Use 3 results for quick lookups, 5-8 for thorough research.

**`google_search` then `scrape_page`** -- when selective reading is needed:

```
mcp__g__google_search
  query: "<topic> <current_year> <prior_year>"
  num_results: 5
```

Then scrape only the most relevant URLs from the results.

**`sequential_search`** -- for multi-step research across 3+ queries:

```
mcp__g__sequential_search
  searchStep: "Starting research on <topic>"
  stepNumber: 1
  nextStepNeeded: true
```

Track findings across steps. Record sources with quality scores.

### g Rules

- Always append year strings to queries (current year and prior year)
- Prefer `search_and_scrape` over separate search + scrape calls
- Use `scrape_page` with `mode: "preview"` first on large pages to check size before full fetch
- Cite source URLs in findings
- State clearly when information could not be found

---

## Output

Report findings inline in the conversation. Include:
- Source citations (URLs from g, library IDs from c7)
- Version numbers when relevant
- Date of source material when available from g results
- Clear statement if information was not found or results were inconclusive

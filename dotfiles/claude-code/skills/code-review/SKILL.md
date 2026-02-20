---
name: code-review
description: Launch parallel code reviews using OpenAI, Gemini, and Claude via opencode run.
user-invocable: true
argument-hint: "[custom review prompt or focus area]"
---

STARTER_CHARACTER = 🕵️‍♂️

# Code Review Skill

Launch parallel code reviews using three LLMs via `opencode run` as background bash tasks.

Arguments: $ARGUMENTS

- If `$ARGUMENTS` is provided, use it as the review prompt instead of the default.
- If `$ARGUMENTS` is empty, use the Default Review Prompt below.

## Procedure

1. Delete previous review files:

```bash
rm -f .llmdocs/review-openai.md .llmdocs/review-gemini.md .llmdocs/review-claude.md
mkdir -p .llmdocs
```

2. Launch all three reviews as background bash tasks. Substitute `REVIEW_PROMPT` with the user-provided prompt from `$ARGUMENTS`, or the Default Review Prompt if none was provided.

```bash
opencode run -m openai/gpt-5.2-pro --title "OpenAI Code Review" "REVIEW_PROMPT Write your review to .llmdocs/review-openai.md"
```

```bash
opencode run -m google/gemini-3-pro-preview --title "Gemini Code Review" "REVIEW_PROMPT Write your review to .llmdocs/review-gemini.md"
```

```bash
opencode run -m az-anthropic/claude-opus-4-6 --title "Claude Code Review" "REVIEW_PROMPT Write your review to .llmdocs/review-claude.md"
```

3. After launching, confirm the three background tasks are running and remind the user to check `.llmdocs/` for results.

## Default Review Prompt

Used when `$ARGUMENTS` is empty. This is the full prompt passed to each `opencode run` command:

```
You are performing a code review of this project. Your job is to find problems, not give compliments, not provide validation.

## Instructions

- Use the repomix MCP tool to pack the repository into a single context. This gives you the full codebase in one call. Do NOT read files individually.
- After packing, read CLAUDE.md and .llmdocs/architecture.md (if present) for project context.
- Write the review file directly. Do NOT ask for permission or clarifying questions. This is a non-interactive code review.
- Every finding MUST cite specific file, line number, and function name.
- Rate each finding: High / Medium / Low. High are "must". Medium are "should". Low are "could".
- ONLY report defects, flaws, risks, and recommendations for improvement.
- ALWAYS write the review file as your FIRST action after analysis.
- NEVER exit without writing a review file.
- Do NOT use scripts or automated scanners. Reason about the code, then write findings.
- Do NOT delegate to sub-agents. Do the review yourself.
- Do NOT describe what works correctly.
- Do NOT praise existing code.
- Do NOT say things like "well-structured", "correctly implements", or "good use of". If something is fine, skip it silently.
- If a component has no issues, omit it entirely rather than noting it has no findings.

## Review Areas

For each area, report ONLY defects and recommendations. Skip areas with no findings.

### Security
- [ ] Authentication and authorization
- [ ] Secret handling (env vars, config files, key management)
- [ ] Input validation and injection risks (SQL, command, template, XSS)
- [ ] RBAC scope and least-privilege
- [ ] Network policies and ingress configuration
- [ ] Container security context

### Architecture & Design
- [ ] Component boundaries and separation of concerns
- [ ] Interface design and dependency injection
- [ ] Error propagation patterns
- [ ] State management
- [ ] Isolation model

### Correctness & Bugs
- [ ] Race conditions and concurrency issues
- [ ] Nil pointer / index-out-of-bounds risks
- [ ] Resource leaks (goroutines, connections, file handles)
- [ ] Edge cases in lifecycle operations (partial rollback, concurrent mutations)

### Testing
- [ ] Test coverage gaps
- [ ] Mock correctness vs real behavior
- [ ] Missing negative / error path tests
- [ ] Integration test completeness

### Operational Readiness
- [ ] Health checks and readiness probes
- [ ] Graceful shutdown
- [ ] Resource limits and requests
- [ ] Logging and structured observability
- [ ] Deployment upgrade/rollback safety

### Performance
- [ ] N+1 queries or excessive API calls
- [ ] Connection pooling
- [ ] Template parsing and caching
- [ ] Timeout configuration

### Code Quality
- [ ] Dead code and unused exports
- [ ] Naming consistency
- [ ] Duplicated logic
- [ ] Language idioms and error handling patterns
```

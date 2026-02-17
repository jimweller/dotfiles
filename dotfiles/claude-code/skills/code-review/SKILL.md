---
name: code-review
description: Launch parallel code reviews using OpenAI, Gemini, and Claude via opencode run.
user-invocable: true
---

STARTER_CHARACTER = 🕵️‍♂️

# Code Review Skill

Launch parallel code reviews using three LLMs via `opencode run` as background bash tasks.

## Procedure

1. Delete previous review files:

```bash
rm -f .llmdocs/review-openai.md .llmdocs/review-gemini.md .llmdocs/review-claude.md
mkdir -p .llmdocs
```

2. Launch all three reviews as background bash tasks using the structured review prompt below. Substitute `REVIEW_PROMPT` with the full prompt text.

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

## Review Prompt

The full prompt passed to each `opencode run` command:

```
You are performing a code review of this project. Your job is to find problems, not give compliments, not provide validation.

## Instructions

- First, read README.md, CLAUDE.md, .llmdocs/architecture.md (if present) to understand the project purpose, architecture, and conventions.
- Run `git ls-files` to discover tracked files. Only review git-tracked files. Skip anything in .gitignore.
- You MUST read every source file from `git ls-files` individually and fully before writing any review.
- Do NOT summarize, skim, or batch-read files. Read every file from `git ls-files`.
- Write the review file directly. Do NOT ask for permission or clarifying questions. This is a non-interactive code review.
- Every finding MUST cite specific file, line number, and function name.
- Rate each finding: High / Medium / Low. High are "must". Medium are "should". Low are "could".
- ONLY report defects, flaws, risks, and recommendations for improvement.
- ALWAYS write the review file as your FIRST action after analysis. 
- NEVER exit without writing a review file.
- Do NOT use scripts or automated scanners. Read each file, reason about it, then write findings.
- Do NOT delegate to sub-agents. Do the review yourself.
- Do NOT describe what works correctly. 
- Do NOT praise existing code. 
- Do NOT say things like "well-structured", "correctly implements", or "good use of". If something is fine, skip it silently.
- If a component has no issues, omit it entirely rather than noting it has no findings.


## Component Discovery

Before reviewing, run `git ls-files` to get the list of tracked files. Only review tracked files. Do NOT read files or directories excluded by .gitignore. Do not rely on a hardcoded file list.

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

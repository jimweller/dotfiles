---
name: code-review
description: Launch parallel code reviews using OpenAI, Gemini, and Claude via opencode run.
user-invocable: true
argument-hint: "[custom review prompt or focus area]"
---

STARTER_CHARACTER = 🕵️‍♂️

# Code Review Skill

Launch parallel multi-pass code reviews using three LLMs via `opencode run` as background bash tasks. Each model spawns 8 focused subagent reviewers (one per area) for thorough coverage.

Arguments: $ARGUMENTS

## Procedure

1. Delete previous review files:

```bash
rm -f .llmdocs/_review-openai.md .llmdocs/_review-gemini.md .llmdocs/_review-claude.md
mkdir -p .llmdocs
```

2. Build `REVIEW_PROMPT` by concatenating the **Orchestrator Prompt** with the **Additional Context** (if `$ARGUMENTS` is provided).

3. Launch all three reviews as background bash tasks. The prompt string for each command is `REVIEW_PROMPT` + the output file instruction.

```bash
opencode run -m openai/gpt-5.2-pro --title "OpenAI Code Review" "<REVIEW_PROMPT> Write your review to .llmdocs/_review-openai.md"
```

```bash
opencode run -m google/gemini-3.1-pro-preview --title "Gemini Code Review" "<REVIEW_PROMPT> Write your review to .llmdocs/_review-gemini.md"
```

```bash
opencode run -m az-anthropic/claude-opus-4-6 --title "Claude Code Review" "<REVIEW_PROMPT> Write your review to .llmdocs/_review-claude.md"
```

4. After launching, confirm the three background tasks are running and remind the user to check `.llmdocs/` for results.

## Orchestrator Prompt

Always included in every review prompt:

```
You are a code review orchestrator. Your job is to coordinate a thorough multi-pass review.

## Setup
- Use the repomix MCP tool to pack the repository into a single context. This gives you the full codebase in one call. Do NOT read files directly.
- After packing, read CLAUDE.md and .llmdocs/architecture.md (if present) for project context.

## Procedure
1. Spawn ALL of the following review subagents in PARALLEL using the Task tool:
   - review-security
   - review-architecture
   - review-solid
   - review-correctness
   - review-testing
   - review-ops
   - review-performance
   - review-quality

   For each, use Task with subagent_type set to the agent name and a prompt of:
   "Review this project. Return your findings as markdown."

2. Collect the text output from all 8 subagents.
3. Combine them into a single review file with each area as a section header.
4. Write the combined review to the output file specified below.

## Rules
- Do NOT review code yourself. Delegate ALL review work to subagents.
- Do NOT skip any subagent. Launch all 8.
- Do NOT ask questions. This is non-interactive.
- If a subagent returns "No findings", omit that section.
- Write the review file directly. Do NOT ask for permission.
- ALWAYS write the review file as your FIRST action after collecting subagent results.
- NEVER exit without writing a review file.
```

## Additional Context

When `$ARGUMENTS` is provided, append the following to each subagent's prompt:

```
Additional review context from the user: $ARGUMENTS
```

When `$ARGUMENTS` is empty, subagents use their built-in focus area checklists with no additional context.

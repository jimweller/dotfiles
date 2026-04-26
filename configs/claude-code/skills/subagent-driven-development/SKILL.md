---
name: subagent-driven-development
description: "Execute an implementation plan by dispatching one fresh subagent per task with two-stage review (spec compliance, then code quality)"
argument-hint: "<plan-file-path>"
disable-model-invocation: true
---

<!-- markdownlint-disable-file MD041 -->

STARTER_CHARACTER = 🎬

# Subagent-Driven Development

Execute a plan by dispatching a fresh subagent per task, with two-stage review after each: spec compliance review first, then code quality review.

Arguments: $ARGUMENTS

The argument is the path to a plan file. If `$ARGUMENTS` is empty, look in `.llmtmp/` for plan files (matches local convention used by ralph-builder and code-reviews).

**Why subagents:** Tasks delegate to subagents with isolated context. Precise instructions and curated context keep the subagent focused and successful. Subagents do not inherit session context or history. The controller curates exactly what each subagent needs. This also preserves controller context for coordination work.

**Core principle:** Fresh subagent per task plus two-stage review (spec then quality) yields high quality and fast iteration.

## When to Use

Use this skill when:

- A written implementation plan exists with multiple tasks
- Tasks are mostly independent (no tight coupling)
- The work should stay in this session

If tasks are tightly coupled or the plan does not yet exist, use a different approach. The brainstorming and plan-creation skills are not provided here; use whatever local tooling generates the plan first.

This skill is the same-session execution pattern. Fresh subagent per task, no context pollution, two-stage review after each task, fast iteration.

## Prerequisites

- `/review-quick` is invoked per task. It needs git access to compute deltas; no extra binary.
- `/review-full` is invoked once at the end. It shells out to `npx repomix` and uses the repomix MCP server. If repomix is unavailable, the final whole-codebase audit cannot run; either install it or skip the final-review step.

## The Process

The controller follows this loop:

1. Read the plan file once. Extract every task with its full text and surrounding context. Create a TodoWrite list with all tasks.

2. For each task:
   1. Dispatch the implementer subagent with the full task text and curated context (use @implementer-prompt.md as the template).
   2. If the implementer asks questions, answer them and re-dispatch.
   3. The implementer implements, tests, commits, and self-reviews. It returns a status: DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, or BLOCKED.
   4. Handle the status (see Handling Implementer Status below). If DONE or DONE_WITH_CONCERNS, proceed to spec compliance review.
   5. Dispatch the spec compliance reviewer subagent (use @spec-reviewer-prompt.md as the template).
   6. If the spec reviewer finds issues, the implementer fixes them. Re-dispatch the spec reviewer until it confirms compliance.
   7. Once spec compliance passes, invoke the `/review-quick` skill. It auto-detects the just-committed task changes and dispatches 8 specialized review agents in parallel. Returns a consolidated report.
   8. If `/review-quick` reports High or Medium severity findings, the implementer fixes them. Re-invoke `/review-quick` until it returns no High/Medium findings.
   9. Mark the task complete in TodoWrite.

3. After all tasks are complete, invoke `/review-full` for a whole-codebase audit of the implementation.

4. Hand off to the `/commit` skill to finalize the work.

## Model Selection

Use the least powerful model that can handle each role to conserve cost and increase speed.

- Mechanical implementation tasks (isolated functions, clear specs, 1-2 files): a fast, cheap model. Most implementation tasks are mechanical when the plan is well-specified.
- Integration and judgment tasks (multi-file coordination, pattern matching, debugging): a standard model.
- Architecture, design, and review tasks: the most capable available model.

Task complexity signals:

- Touches 1-2 files with a complete spec: cheap model
- Touches multiple files with integration concerns: standard model
- Requires design judgment or broad codebase understanding: most capable model

## Handling Implementer Status

Implementer subagents report one of four statuses. Handle each appropriately.

**DONE:** Proceed to spec compliance review.

**DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts. Read the concerns before proceeding. If the concerns are about correctness or scope, address them before review. If they are observations (e.g., "this file is getting large"), note them and proceed to review.

**NEEDS_CONTEXT:** The implementer needs information that was not provided. Provide the missing context and re-dispatch.

**BLOCKED:** The implementer cannot complete the task. Assess the blocker:

1. If it is a context problem, provide more context and re-dispatch with the same model.
2. If the task requires more reasoning, re-dispatch with a more capable model.
3. If the task involves debugging a stubborn failure, re-dispatch with the systematic-debugging skill in scope.
4. If the task is too large, break it into smaller pieces.
5. If the plan itself is wrong, escalate to the user.

Never ignore an escalation or force the same model to retry without changes. If the implementer said it is stuck, something needs to change.

## Prompt Templates

- @implementer-prompt.md - Dispatch implementer subagent
- @spec-reviewer-prompt.md - Dispatch spec compliance reviewer subagent

Code quality review uses the `/review-quick` skill, which dispatches 8 specialized review agents in parallel. No template needed in this skill.

## Example Workflow

Plan extracted, 5 tasks identified, TodoWrite created.

Task 1: Hook installation script.

Dispatch the implementer with full task text and context. The implementer asks: "Should the hook be installed at user or system level?" The user answers: "User level." The implementer implements, tests, commits, self-reviews, and reports DONE.

Dispatch the spec reviewer. It returns: spec compliant.

Invoke `/review-quick`. It dispatches 8 specialized review agents in parallel and returns: no High or Medium findings (one Low finding noted but not blocking).

Mark Task 1 complete.

Task 2: Recovery modes.

Dispatch the implementer. It reports DONE.

Dispatch the spec reviewer. It returns: missing progress reporting (spec says "report every 100 items"); extra unrequested `--json` flag.

The implementer fixes both issues. Re-dispatch the spec reviewer. Returns: spec compliant.

Invoke `/review-quick`. Returns: Code Quality flagged a Medium finding for magic number `100`.

The implementer extracts a `PROGRESS_INTERVAL` constant. Re-invoke `/review-quick`. Returns: no High or Medium findings.

Mark Task 2 complete.

Continue for remaining tasks. After all tasks, invoke `/review-full` for a whole-codebase audit. Hand off to `/commit`.

## Advantages

vs. manual execution:

- Subagents follow TDD naturally
- Fresh context per task (no confusion)
- Subagents can ask questions before AND during work

Quality gates:

- Self-review catches issues before handoff
- Two-stage review: spec compliance, then code quality
- Review loops ensure fixes actually work
- Spec compliance prevents over- or under-building
- Code quality ensures implementation is well-built

Cost:

- More subagent invocations (implementer plus 2 reviewers per task)
- Controller does more prep work (extracting all tasks upfront)
- Review loops add iterations
- Catches issues early (cheaper than debugging later)

## Red Flags

Never:

- Start implementation on main or master branch without explicit user consent
- Skip reviews (spec compliance OR code quality)
- Proceed with unfixed issues
- Dispatch multiple implementation subagents in parallel (conflicts)
- Make the subagent read the plan file (provide full text instead)
- Skip scene-setting context (the subagent needs to understand where the task fits)
- Ignore subagent questions (answer before letting them proceed)
- Accept "close enough" on spec compliance (spec reviewer found issues means not done)
- Skip review loops (reviewer found issues means implementer fixes means review again)
- Let implementer self-review replace actual review (both are needed)
- Start code quality review before spec compliance is approved (wrong order)
- Move to next task while either review has open issues

If a subagent asks questions:

- Answer clearly and completely
- Provide additional context if needed
- Do not rush them into implementation

If a reviewer finds issues:

- Implementer (same subagent) fixes them
- Reviewer reviews again
- Repeat until approved
- Do not skip the re-review

If a subagent fails the task:

- Dispatch a fix subagent with specific instructions
- Do not try to fix manually (context pollution)

## Integration

Subagents should use:

- test-driven-development - Subagents follow TDD for each task
- systematic-debugging - When BLOCKED on a stubborn failure
- verify-claims - Verify subagent reports against VCS diff before accepting

Code review:

- /review-quick - Per-task code quality review (auto-dispatched after spec compliance passes)
- /review-full - Whole-codebase audit after all tasks complete

Workflow handoff:

- /commit - Finalize the work after all tasks and final review pass

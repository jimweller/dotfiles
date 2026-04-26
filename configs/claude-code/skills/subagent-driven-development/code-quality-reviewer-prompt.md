# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.

Purpose: verify implementation is well-built (clean, tested, maintainable).

**Only dispatch after spec compliance review passes.** Quality review on wrong-built code is wasted work.

## Dispatch

```text
Task tool with subagent_type: code-reviewer
  description: "Code quality review for Task N"
  prompt: |
    You are reviewing code changes for production readiness.

    Your task:
    1. Review {WHAT_WAS_IMPLEMENTED}
    2. Compare against {PLAN_OR_REQUIREMENTS}
    3. Check code quality, architecture, testing
    4. Categorize issues by severity
    5. Assess production readiness

    ## What Was Implemented

    {DESCRIPTION}

    ## Requirements/Plan

    {PLAN_REFERENCE}

    ## Git Range to Review

    Base: {BASE_SHA}
    Head: {HEAD_SHA}

    Run:
      git diff --stat {BASE_SHA}..{HEAD_SHA}
      git diff {BASE_SHA}..{HEAD_SHA}

    ## Review Checklist

    Code Quality:
    - Clean separation of concerns?
    - Proper error handling?
    - Type safety (if applicable)?
    - DRY principle followed?
    - Edge cases handled?

    Architecture:
    - Sound design decisions?
    - Scalability considerations?
    - Performance implications?
    - Security concerns?

    Testing:
    - Tests actually test logic (not mocks)?
    - Edge cases covered?
    - Integration tests where needed?
    - All tests passing?

    Requirements:
    - All plan requirements met?
    - Implementation matches spec?
    - No scope creep?
    - Breaking changes documented?

    Production Readiness:
    - Migration strategy (if schema changes)?
    - Backward compatibility considered?
    - Documentation complete?
    - No obvious bugs?

    Plan Adherence:
    - Does each file have one clear responsibility with a well-defined interface?
    - Are units decomposed so they can be understood and tested independently?
    - Is the implementation following the file structure from the plan?
    - Did this implementation create new files that are already large, or significantly grow existing files? Do not flag pre-existing file sizes - focus on what this change contributed.

    ## Output Format

    Strengths:
    [What is well done. Be specific.]

    Issues:

    Critical (Must Fix):
    [Bugs, security issues, data loss risks, broken functionality]

    Important (Should Fix):
    [Architecture problems, missing features, poor error handling, test gaps]

    Minor (Nice to Have):
    [Code style, optimization opportunities, documentation improvements]

    For each issue:
    - File:line reference
    - What is wrong
    - Why it matters
    - How to fix (if not obvious)

    Recommendations:
    [Improvements for code quality, architecture, or process]

    Assessment:
    Ready to merge? [Yes / No / With fixes]
    Reasoning: [Technical assessment in 1-2 sentences]

    ## Critical Rules

    DO:
    - Categorize by actual severity (not everything is Critical)
    - Be specific (file:line, not vague)
    - Explain WHY issues matter
    - Acknowledge strengths
    - Give clear verdict

    DO NOT:
    - Say "looks good" without checking
    - Mark nitpicks as Critical
    - Give feedback on code you did not review
    - Be vague ("improve error handling")
    - Avoid giving a clear verdict
```

## Placeholders

The controller fills these before dispatch:

- `{WHAT_WAS_IMPLEMENTED}` - One-sentence description of the change
- `{PLAN_OR_REQUIREMENTS}` - Plan task reference (file path and task number)
- `{BASE_SHA}` - Commit SHA before this task started (e.g., from previous task or main)
- `{HEAD_SHA}` - Current commit SHA (output of `git rev-parse HEAD`)
- `{DESCRIPTION}` - Multi-sentence summary of the implementation
- `{PLAN_REFERENCE}` - Path to plan file plus the task number

## Notes

- The `code-reviewer` agent is defined at `~/.claude/agents/code-reviewer.md` (sourced from `configs/claude-code/agents/code-reviewer.md` in dotfiles).
- Dispatch with `subagent_type: code-reviewer`, not `general-purpose`.
- The agent's system prompt is the Senior Code Reviewer role definition. The dispatch prompt above adds task-specific context.

# Implementer Subagent Prompt Template

Use this template when dispatching an implementer subagent.

```text
Task tool (general-purpose):
  description: "Implement Task N: [task name]"
  prompt: |
    You are implementing Task N: [task name]

    ## Task Description

    [FULL TEXT of task from plan - paste it here, do not make subagent read file]

    ## Context

    [Scene-setting: where this fits, dependencies, architectural context]

    ## Before You Begin

    If you have questions about:
    - The requirements or acceptance criteria
    - The approach or implementation strategy
    - Dependencies or assumptions
    - Anything unclear in the task description

    Ask them now. Raise any concerns before starting work.

    ## Third-Party API Verification

    If the task touches third-party APIs, libraries, or frameworks, use the /sage skill to verify current API signatures before writing code. Do not rely on training-data memory of API shapes.

    ## Your Job

    Once requirements are clear:
    1. Implement exactly what the task specifies
    2. Write tests (following TDD if task says to)
    3. Verify implementation works
    4. Commit your work
    5. Self-review (see below)
    6. Report back

    Work from: [directory]

    While you work: if you encounter something unexpected or unclear, ask questions. It is always OK to pause and clarify. Do not guess or make assumptions.

    ## Code Organization

    Reasoning is best on code that fits in context at once, and edits are more reliable when files are focused. Keep this in mind:
    - Follow the file structure defined in the plan
    - Each file should have one clear responsibility with a well-defined interface
    - If a file you are creating is growing beyond the plan's intent, stop and report it as DONE_WITH_CONCERNS - do not split files on your own without plan guidance
    - If an existing file you are modifying is already large or tangled, work carefully and note it as a concern in your report
    - In existing codebases, follow established patterns. Improve code you are touching the way a good developer would, but do not restructure things outside your task.

    ## When You Are in Over Your Head

    It is always OK to stop and say "this is too hard." Bad work is worse than no work. There is no penalty for escalating.

    STOP and escalate when:
    - The task requires architectural decisions with multiple valid approaches
    - You need to understand code beyond what was provided and cannot find clarity
    - You feel uncertain about whether your approach is correct
    - The task involves restructuring existing code in ways the plan did not anticipate
    - You have been reading file after file trying to understand the system without progress

    How to escalate: report back with status BLOCKED or NEEDS_CONTEXT. Describe specifically what you are stuck on, what you have tried, and what kind of help you need. The controller can provide more context, re-dispatch with a more capable model, or break the task into smaller pieces.

    ## Before Reporting Back: Self-Review

    Review your work with fresh eyes. Ask:

    Completeness:
    - Did I fully implement everything in the spec?
    - Did I miss any requirements?
    - Are there edge cases I did not handle?

    Quality:
    - Is this my best work?
    - Are names clear and accurate (match what things do, not how they work)?
    - Is the code clean and maintainable?

    Discipline:
    - Did I avoid overbuilding (YAGNI)?
    - Did I only build what was requested?
    - Did I follow existing patterns in the codebase?

    Testing:
    - Do tests actually verify behavior (not just mock behavior)?
    - Did I follow TDD if required?
    - Are tests comprehensive?

    If issues are found during self-review, fix them now before reporting.

    ## Report Format

    When done, report:
    - Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - What you implemented (or what you attempted, if blocked)
    - What you tested and test results
    - Files changed
    - Self-review findings (if any)
    - Any issues or concerns

    Use DONE_WITH_CONCERNS if you completed the work but have doubts about correctness. Use BLOCKED if you cannot complete the task. Use NEEDS_CONTEXT if you need information that was not provided. Never silently produce work you are unsure about.
```

---
name: systematic-debugging
description: "Use when a bug or test failure persists after one fix attempt, or for any production bug or multi-component failure"
---

<!-- markdownlint-disable-file MD041 -->

STARTER_CHARACTER = 🐛

# Systematic Debugging

## Overview

Random fixes waste time and create new bugs. Quick patches mask underlying issues.

**Core principle:** ALWAYS find root cause before attempting fixes. Symptom fixes are failure.

**Violating the letter of this process is violating the spirit of debugging.**

## The Iron Law

```text
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If Phase 1 is incomplete, no fixes can be proposed.

## When to Use

Use for any technical issue:

- Test failures
- Bugs in production
- Unexpected behavior
- Performance problems
- Build failures
- Integration issues

Use this especially when:

- Under time pressure (emergencies make guessing tempting)
- "Just one quick fix" seems obvious
- Multiple fixes have already been tried
- A previous fix did not work
- The issue is not fully understood

Do not skip when:

- The issue seems simple (simple bugs have root causes too)
- The deadline is tight (rushing guarantees rework)
- Manager wants it fixed NOW (systematic is faster than thrashing)

## The Four Phases

Each phase must be complete before proceeding to the next.

### Phase 1: Root Cause Investigation

Before attempting any fix:

1. **Read error messages carefully**
   - Do not skip past errors or warnings
   - Errors often contain the exact solution
   - Read stack traces completely
   - Note line numbers, file paths, error codes

2. **Reproduce consistently**
   - Can the failure be triggered reliably?
   - What are the exact steps?
   - Does it happen every time?
   - If not reproducible: gather more data, do not guess

3. **Check recent changes**
   - What changed that could cause this?
   - Git diff, recent commits
   - New dependencies, config changes
   - Environmental differences

4. **Gather evidence in multi-component systems**

   When the system has multiple components (CI to build to signing, API to service to database):

   Before proposing fixes, add diagnostic instrumentation. For each component boundary:
   - Log what data enters component
   - Log what data exits component
   - Verify environment/config propagation
   - Check state at each layer

   Run once to gather evidence showing where it breaks. Then analyze evidence to identify failing component. Then investigate that specific component.

   Example multi-layer instrumentation:

   ```bash
   # Layer 1: Workflow
   echo "=== Secrets available in workflow: ==="
   echo "IDENTITY: ${IDENTITY:+SET}${IDENTITY:-UNSET}"

   # Layer 2: Build script
   echo "=== Env vars in build script: ==="
   env | grep IDENTITY || echo "IDENTITY not in environment"

   # Layer 3: Signing script
   echo "=== Keychain state: ==="
   security list-keychains
   security find-identity -v

   # Layer 4: Actual signing
   codesign --sign "$IDENTITY" --verbose=4 "$APP"
   ```

   This reveals which layer fails (secrets to workflow OK, workflow to build broken).

5. **Trace data flow**

   When the error is deep in the call stack, see @root-cause-tracing.md in this directory for the complete backward tracing technique.

   Quick version:
   - Where does the bad value originate?
   - What called this with bad value?
   - Keep tracing up until the source is found
   - Fix at source, not at symptom

### Phase 2: Pattern Analysis

Find the pattern before fixing.

1. **Find working examples**
   - Locate similar working code in the same codebase
   - What works that is similar to what is broken?

2. **Compare against references**
   - If implementing a pattern, read the reference implementation completely
   - Do not skim, read every line
   - Understand the pattern fully before applying

3. **Identify differences**
   - What is different between working and broken?
   - List every difference, however small
   - Do not assume "that cannot matter"

4. **Understand dependencies**
   - What other components does this need?
   - What settings, config, environment?
   - What assumptions does it make?

### Phase 3: Hypothesis and Testing

Apply the scientific method.

1. **Form a single hypothesis**
   - State clearly: "X is the root cause because Y"
   - Write it down
   - Be specific, not vague

2. **Test minimally**
   - Make the smallest possible change to test the hypothesis
   - One variable at a time
   - Do not fix multiple things at once

3. **Verify before continuing**
   - Did it work? Yes: Phase 4
   - Did it not work? Form a NEW hypothesis
   - Do not stack more fixes on top

4. **When stuck**
   - State "I do not understand X"
   - Do not pretend to know
   - Ask for help
   - Research more

### Phase 4: Implementation

Fix the root cause, not the symptom.

1. **Create failing test case**
   - Simplest possible reproduction
   - Automated test if possible
   - One-off test script if no framework
   - Must have before fixing
   - Use the test-driven-development skill for writing proper failing tests
   - Use the verify-claims skill to prove the test catches the bug (red-green-revert-restore)

2. **Implement single fix**
   - Address the root cause identified
   - One change at a time
   - No "while I'm here" improvements
   - No bundled refactoring

3. **Verify fix**
   - Test passes now?
   - No other tests broken?
   - Issue actually resolved?

4. **If fix does not work**
   - STOP
   - Count: how many fixes have been tried?
   - If less than 3: return to Phase 1, re-analyze with new information
   - If 3 or more: STOP and question the architecture (step 5 below)
   - Do NOT attempt fix #4 without architectural discussion

5. **If 3+ fixes failed: question architecture**

   Patterns indicating an architectural problem:
   - Each fix reveals new shared state, coupling, or problem in a different place
   - Fixes require "massive refactoring" to implement
   - Each fix creates new symptoms elsewhere

   STOP and question fundamentals:
   - Is this pattern fundamentally sound?
   - Is the team "sticking with it through sheer inertia"?
   - Should the architecture be refactored vs. continuing to fix symptoms?

   Discuss with the user before attempting more fixes.

   This is not a failed hypothesis, this is a wrong architecture.

## Red Flags - STOP and Follow Process

Catch these thoughts:

- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes, run tests"
- "Skip the test, manually verify"
- "It's probably X, fix that"
- "Don't fully understand but this might work"
- "Pattern says X but adapt it differently"
- "Here are the main problems: [lists fixes without investigation]"
- Proposing solutions before tracing data flow
- "One more fix attempt" when already tried 2+
- Each fix reveals new problem in different place

All of these mean: STOP. Return to Phase 1.

If 3+ fixes failed, question the architecture (see Phase 4 step 5).

## User Signals That The Approach Is Wrong

Watch for these redirections:

- "Is that not happening?" - assumed without verifying
- "Will it show us...?" - should have added evidence gathering
- "Stop guessing" - proposing fixes without understanding
- "Ultrathink this" - question fundamentals, not just symptoms
- "We're stuck?" (frustrated) - the approach is not working

When these appear: STOP. Return to Phase 1.

## Common Rationalizations

| Excuse                                       | Reality                                                                  |
| -------------------------------------------- | ------------------------------------------------------------------------ |
| "Issue is simple, no need for process"       | Simple issues have root causes too. Process is fast for simple bugs.     |
| "Emergency, no time for process"             | Systematic debugging is faster than guess-and-check thrashing.           |
| "Just try this first, then investigate"      | First fix sets the pattern. Do it right from the start.                  |
| "Write the test after confirming fix works"  | Untested fixes do not stick. Test first proves it.                       |
| "Multiple fixes at once saves time"          | Cannot isolate what worked. Causes new bugs.                             |
| "Reference too long, adapt the pattern"      | Partial understanding guarantees bugs. Read it completely.               |
| "I see the problem, fix it"                  | Seeing symptoms is not understanding root cause.                         |
| "One more fix attempt" (after 2+ failures)   | 3+ failures means architectural problem. Question pattern, do not retry. |

## Quick Reference

| Phase             | Key Activities                                                | Success Criteria                |
| ----------------- | ------------------------------------------------------------- | ------------------------------- |
| 1. Root Cause     | Read errors, reproduce, check changes, gather evidence        | Understand WHAT and WHY         |
| 2. Pattern        | Find working examples, compare                                 | Identify differences            |
| 3. Hypothesis     | Form theory, test minimally                                    | Confirmed or new hypothesis     |
| 4. Implementation | Create test, fix, verify                                       | Bug resolved, tests pass        |

## When Process Reveals "No Root Cause"

If systematic investigation reveals the issue is truly environmental, timing-dependent, or external:

1. The process is complete
2. Document what was investigated
3. Implement appropriate handling (retry, timeout, error message)
4. Add monitoring/logging for future investigation

But: 95% of "no root cause" cases are incomplete investigation.

## Supporting Techniques

These techniques are part of systematic debugging and live in this directory:

- @root-cause-tracing.md - Trace bugs backward through call stack to find original trigger
- @defense-in-depth.md - Add validation at multiple layers after finding root cause
- @condition-based-waiting.md - Replace arbitrary timeouts with condition polling

Related skills:

- test-driven-development - For creating failing test case (Phase 4, Step 1)
- verify-claims - Verify fix worked before claiming success

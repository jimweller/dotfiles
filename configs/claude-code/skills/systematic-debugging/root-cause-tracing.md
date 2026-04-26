# Root Cause Tracing

## Overview

Bugs often manifest deep in the call stack (git init in wrong directory, file created in wrong location, database opened with wrong path). The instinct is to fix where the error appears, but that is treating a symptom.

**Core principle:** Trace backward through the call chain until the original trigger is found, then fix at the source.

## When to Use

Use when:

- Error happens deep in execution (not at entry point)
- Stack trace shows long call chain
- Unclear where invalid data originated
- Need to find which test or code triggers the problem

## The Tracing Process

### 1. Observe the symptom

```text
Error: git init failed in /Users/jesse/project/packages/core
```

### 2. Find immediate cause

What code directly causes this?

```typescript
await execFileAsync('git', ['init'], { cwd: projectDir });
```

### 3. Ask: what called this?

```text
WorktreeManager.createSessionWorktree(projectDir, sessionId)
  called by Session.initializeWorkspace()
  called by Session.create()
  called by test at Project.create()
```

### 4. Keep tracing up

What value was passed?

- `projectDir = ''` (empty string)
- Empty string as `cwd` resolves to `process.cwd()`
- That is the source code directory

### 5. Find original trigger

Where did empty string come from?

```typescript
const context = setupCoreTest(); // Returns { tempDir: '' }
Project.create('name', context.tempDir); // Accessed before beforeEach
```

## Adding Stack Traces

When manual tracing is not possible, add instrumentation:

```typescript
// Before the problematic operation
async function gitInit(directory: string) {
  const stack = new Error().stack;
  console.error('DEBUG git init:', {
    directory,
    cwd: process.cwd(),
    nodeEnv: process.env.NODE_ENV,
    stack,
  });

  await execFileAsync('git', ['init'], { cwd: directory });
}
```

Critical: use `console.error()` in tests, not logger - logger may not show.

Run and capture:

```bash
npm test 2>&1 | grep 'DEBUG git init'
```

Analyze stack traces:

- Look for test file names
- Find the line number triggering the call
- Identify the pattern (same test? same parameter?)

## Finding Which Test Causes Pollution

When state appears during tests but the source test is unknown, run tests one at a time and check for the pollution after each. A bisection approach narrows it down quickly: run half the suite, check, then split the half that produced the pollution. Repeat until the offending test is isolated.

## Real Example: Empty projectDir

Symptom: `.git` created in `packages/core/` (source code)

Trace chain:

1. `git init` runs in `process.cwd()` because cwd parameter is empty
2. WorktreeManager called with empty projectDir
3. Session.create() passed empty string
4. Test accessed `context.tempDir` before beforeEach
5. setupCoreTest() returns `{ tempDir: '' }` initially

Root cause: top-level variable initialization accessing empty value.

Fix: made tempDir a getter that throws if accessed before beforeEach.

Also added defense-in-depth:

- Layer 1: Project.create() validates directory
- Layer 2: WorkspaceManager validates not empty
- Layer 3: NODE_ENV guard refuses git init outside tmpdir
- Layer 4: Stack trace logging before git init

## Key Principle

Trace backward from the immediate cause. Ask "what called this?" at each level. Continue until reaching the source, then fix at the source. Add validation at each layer to make the bug impossible.

NEVER fix just where the error appears. Trace back to find the original trigger.

## Stack Trace Tips

- In tests: use `console.error()` not logger - logger may be suppressed
- Before operation: log before the dangerous operation, not after it fails
- Include context: directory, cwd, environment variables, timestamps
- Capture stack: `new Error().stack` shows complete call chain

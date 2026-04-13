---
name: update-all-docs
description: Update all project docs (README.md + CLAUDE.md + .llmdocs/) in parallel.
disable-model-invocation: true
context: fork
---

<!-- markdownlint-disable-file MD041 -->

STARTER_CHARACTER = 📚

# Update All Documentation

Arguments: $ARGUMENTS

## Step 1: Run both doc updates in parallel

Spawn two subagents using the Agent tool:

**Agent 1:** Run /update-llm-docs $ARGUMENTS
**Agent 2:** Run /update-readme $ARGUMENTS

## Step 2: Report

List all files created or modified across both agents.

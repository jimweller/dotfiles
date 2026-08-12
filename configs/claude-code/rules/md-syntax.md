---
paths:
  - "**/*.md"
  - "!.llmtmp/*"
  - "!.llmtmp/**/*"
  - "!.llmdocs/*"
  - "!.llmdocs/**/*"
  - "!**/SKILL.md"
---

# Markdown Files

When writing or editing markdown files, invoke the `/md-syntax` skill for authoring guidelines.

When only reading markdown files, no action is needed.

Skip agent artifacts entirely. `.llmtmp/` scratch, `.llmdocs/` reference docs, `SKILL.md`
files, and Claude Code plan files under `~/.claude/plans/` are read by agents, not by
humans, so authoring guidelines do not apply to them.

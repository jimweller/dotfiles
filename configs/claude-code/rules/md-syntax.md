---
paths:
  - "**/*.md"
  - "!.llmtmp/*"
  - "!.llmtmp/**/*"
  - "!.llmdocs/*"
  - "!.llmdocs/**/*"
  - "!**/SKILL.md"
  - "!**/evals/**/prompt.md"
  - "!**/evals/**/graders/*.md"
  - "!**/output-styles/*.md"
---

# Markdown Files

When writing or editing markdown files, invoke the `/md-syntax` skill for authoring guidelines.

When only reading markdown files, no action is needed.

Skip agent artifacts entirely. `.llmtmp/` scratch, `.llmdocs/` reference docs, `SKILL.md`
files, `claude plugin eval` case fixtures (`evals/**/prompt.md`, `evals/**/graders/*.md`),
Claude Code output style files (`output-styles/*.md`), and Claude Code plan files under
`~/.claude/plans/` are read by agents, not by humans, so authoring guidelines do not apply
to them. A prompt.md's or output style's body is sent to the model verbatim; reformatting
it would change the actual input, and prettier silently strips Private-Use-Area glyphs
(e.g. Nerd Font icons) from prose it reflows.

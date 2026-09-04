---
name: tldr
description: Summarize the previous assistant response into a few lines. Use when the user types /tldr or asks for a shorter version, a recap, or the gist of the last response. Do not use to summarize a document, a file, or a web page.
---

<!-- markdownlint-disable-file MD041 -->

STARTER_CHARACTER = ✂️

# TLDR

Compress the immediately preceding assistant turn. That turn is already in
context. Read it there.

## Rules

- Summarize only the last assistant turn. Not the whole session, not the
  user's messages.
- Run no tools. Open no files. Re-verify nothing. Every fact needed is
  already in context.
- Do not answer the original question again. Add no analysis the previous
  turn did not contain.
- Choose the form that reads fastest for the content: prose for a single
  line of reasoning, a list for parallel items, a table when the items
  share fields.
- Compress by cutting restatement, scaffolding, and derivation, not by
  dropping facts.
- The result should take markedly less effort to read than the turn it
  replaces. A tldr that reads as slowly as the original has failed.
- No preamble, no closing line.
- If the previous turn was itself a tldr, say so and stop.
- If there is no previous assistant turn, say so and stop.

## What survives compression

Keep, even when it costs a line:

- Anything requiring action: commands, file paths, links, pending decisions
- Warnings, security caveats, and stated tradeoffs
- Any fact the previous turn marked unverified or assumed

Drop first:

- Derivations, evidence trails, and supporting data
- Restated context and background
- Anything the previous turn already labeled optional

## Argument

An argument narrows the summary to one topic. `/tldr calendar` returns only
the calendar points. With no argument, cover the whole turn.

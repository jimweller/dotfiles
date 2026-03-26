---
name: transcript-search
description: Search saved session transcripts for past decisions, actions, errors, and context that has left the current conversation window.
---

# Transcript Search

Search `.llmdocs/transcripts/*.jsonl` files to answer questions about past sessions.

## When to use

- User asks about something from a previous session or earlier in a long session
- User references a past decision, error, action, or discussion no longer in context
- User asks "what did we do about X", "when did we fix Y", "what error did we get"

## Transcript location

Transcripts are saved to `.llmdocs/transcripts/` in the current project directory. Each session produces:
- `transcript-{datetime}-{session_id}.jsonl` (full conversation data)
- `transcript-{datetime}-{session_id}.md` (human-readable summary)

## JSONL record types

| type | role | contains | jq selector for text content |
|------|------|----------|------------------------------|
| user | user prompt (string content) | what the user asked | `.message.content` |
| user | tool_result (array content) | command output, file contents, errors | `.message.content[].content` |
| assistant | text | Claude's responses and analysis | `.message.content[] \| select(.type == "text") \| .text` |
| assistant | tool_use | tool calls (name, input) | `.message.content[] \| select(.type == "tool_use") \| .name, .input` |
| assistant | thinking | Claude's reasoning and decision rationale | `.message.content[] \| select(.type == "thinking") \| .thinking` |

## Search procedure

### Step 1: Find matching files

Use the Grep tool to identify which transcript files contain the keyword:

```
Grep pattern="keyword" path=".llmdocs/transcripts" glob="*.jsonl" output_mode="files_with_matches"
```

### Step 2: Get line numbers by content type

Choose which content types to search based on the question:

- "what did we decide" / "what was the plan" -> assistant text + thinking
- "what error did we get" / "what was the output" -> tool_result
- "what did I ask about" -> user prompts
- unclear -> search all types

```bash
F=".llmdocs/transcripts/<matched_file>.jsonl"

# User prompts
rg -n --no-filename '"type":"user".*keyword' "$F" | cut -d: -f1

# Assistant text responses
rg -n --no-filename '"type":"text".*keyword' "$F" | cut -d: -f1

# Tool results (command output, file contents, errors)
rg -n --no-filename '"type":"tool_result".*keyword' "$F" | cut -d: -f1

# Thinking/reasoning
rg -n --no-filename '"type":"thinking".*keyword' "$F" | cut -d: -f1
```

### Step 3: Extract and chunk content

For each matching line, extract the text field with jq and pipe to the chunker.
The chunker shows 400-char windows around each keyword match, merging overlaps, capped at 5 chunks.

**User prompts:**
```bash
sed -n '${LINE}p' "$F" | jq -r '.message.content' | python3 ~/.claude/hooks/chunk-search.py "keyword"
```

**Assistant text:**
```bash
sed -n '${LINE}p' "$F" | jq -r '.message.content[] | select(.type == "text") | .text' | python3 ~/.claude/hooks/chunk-search.py "keyword"
```

**Tool results:**
```bash
sed -n '${LINE}p' "$F" | jq -r '.message.content[] | select(.type == "tool_result") | .content' | python3 ~/.claude/hooks/chunk-search.py "keyword"
```

**Thinking:**
```bash
sed -n '${LINE}p' "$F" | jq -r '.message.content[] | select(.type == "thinking") | .thinking' | python3 ~/.claude/hooks/chunk-search.py "keyword"
```

### Step 4: Get timestamp context

To understand when something happened, extract the timestamp from the same line:
```bash
sed -n '${LINE}p' "$F" | jq -r '.timestamp'
```

## Tips

- Search multiple keywords if the first yields too many or too few results
- If a tool_result is relevant, check the preceding assistant message (line - 1 or - 2) to see what tool call produced it
- The `.md` transcript files are useful for quick browsing but lack tool results and thinking blocks
- Multiple transcript files may exist; search all of them when the user is unsure which session
- Combine results across content types to build a complete picture

---
description: Save the current session transcript to .llmdocs/transcripts/ as JSONL and markdown
---

Run the transcript save hook manually for the current session.

Find the current session's JSONL transcript file under `~/.claude/projects/` and pipe it through the save-transcript hook:

```bash
TRANSCRIPT=$(ls -t ~/.claude/projects/**/*.jsonl 2>/dev/null | head -1)
echo "{\"transcript_path\":\"${TRANSCRIPT}\",\"session_id\":\"manual\",\"cwd\":\"$(pwd)\",\"hook_event_name\":\"ManualSave\",\"reason\":\"manual\"}" | ~/.claude/hooks/save-transcript.sh
```

Report the filenames written to `.llmdocs/transcripts/`.

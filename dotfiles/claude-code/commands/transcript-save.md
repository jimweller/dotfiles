---
description: Ingest the current session transcript into the global memory DB
---

Run the transcript ingest hook manually for the current session.

Find the current session's JSONL transcript file under `~/.claude/projects/` and pipe it through the ingest hook:

```bash
TRANSCRIPT=$(ls -t ~/.claude/projects/**/*.jsonl 2>/dev/null | head -1)
echo "{\"transcript_path\":\"${TRANSCRIPT}\",\"session_id\":\"manual\",\"cwd\":\"$(pwd)\",\"hook_event_name\":\"ManualSave\",\"reason\":\"manual\"}" | ~/.claude/hooks/ingest-transcript.sh
```

Report the session_id ingested and the DB path (`~/.claude/session_memory.db`).

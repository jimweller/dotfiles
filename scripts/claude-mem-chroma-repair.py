#!/usr/bin/env -S uv run --quiet --with chromadb --script
"""Repair Chroma coverage gaps in claude-mem by embedding missing rows directly.

claude-mem's backfill selects rows with `WHERE project = ? AND id > watermark`
(ChromaSync.ts:814). Live sync advances that watermark to the newest synced id,
so rows left unsynced below it are skipped permanently -- the backfill only ever
looks forward. This script ignores watermarks entirely: it compares SQLite
against the documents actually present in Chroma and writes the missing ones.

Document ids, metadata keys, and the embedding function match
ChromaSync.formatObservationDocs / formatSummaryDocs / formatUserPromptDoc
exactly, so repaired documents are indistinguishable from natively synced ones.

The Chroma store is single-writer. Stop chroma-mcp before running:
    pkill -f "chroma-mcp --client-type persistent"

Usage:
    claude-mem-chroma-repair.py            plan only, writes nothing
    claude-mem-chroma-repair.py --apply    embed and write missing documents
"""

import argparse
import json
import os
import sqlite3
import sys
import time

DATA_DIR = os.environ.get("CLAUDE_MEM_DATA_DIR", os.path.expanduser("~/.claude-mem"))
MEM_DB = os.path.join(DATA_DIR, "claude-mem.db")
CHROMA_DIR = os.path.join(DATA_DIR, "chroma")
COLLECTION = "cm__claude-mem"
BATCH = 500

DEFAULT_PLATFORM_SOURCE = "claude"


def normalize_platform_source(value):
    """Port of shared/platform-source.ts normalizePlatformSource."""
    if not value:
        return DEFAULT_PLATFORM_SOURCE
    source = "-".join(value.strip().lower().split())
    if not source:
        return DEFAULT_PLATFORM_SOURCE
    if source == "transcript":
        return "codex"
    for needle in ("codex", "cursor", "claude"):
        if needle in source:
            return needle
    return source


def parse_file_list(value):
    """Port of services/sqlite/observations/files.ts parseFileList."""
    if not value:
        return []
    try:
        parsed = json.loads(value)
    except (ValueError, TypeError):
        return [value]
    return parsed if isinstance(parsed, list) else [str(parsed)]


def parse_json_list(value):
    if not value:
        return []
    try:
        parsed = json.loads(value)
    except (ValueError, TypeError):
        return []
    return parsed if isinstance(parsed, list) else []


def clean(metadata):
    """Chroma rejects None metadata values; upstream drops them the same way."""
    return {k: v for k, v in metadata.items() if v is not None}


def observation_docs(row):
    base = {
        "sqlite_id": row["id"],
        "doc_type": "observation",
        "memory_session_id": row["memory_session_id"],
        "project": row["project"],
        "merged_into_project": row["merged_into_project"],
        "platform_source": normalize_platform_source(row["platform_source"]),
        "created_at_epoch": row["created_at_epoch"],
        "type": row["type"] or "discovery",
        "title": row["title"] or "Untitled",
    }
    if row["subtitle"]:
        base["subtitle"] = row["subtitle"]
    concepts = parse_json_list(row["concepts"])
    if concepts:
        base["concepts"] = ",".join(concepts)
    files_read = parse_file_list(row["files_read"])
    if files_read:
        base["files_read"] = ",".join(files_read)
    files_modified = parse_file_list(row["files_modified"])
    if files_modified:
        base["files_modified"] = ",".join(files_modified)

    docs = []
    if row["narrative"]:
        docs.append((f"obs_{row['id']}_narrative", row["narrative"],
                     clean({**base, "field_type": "narrative"})))
    if row["text"]:
        docs.append((f"obs_{row['id']}_text", row["text"],
                     clean({**base, "field_type": "text"})))
    for index, fact in enumerate(parse_json_list(row["facts"])):
        docs.append((f"obs_{row['id']}_fact_{index}", fact,
                     clean({**base, "field_type": "fact", "fact_index": index})))
    return docs


SUMMARY_FIELDS = ("request", "investigated", "learned", "completed", "next_steps", "notes")


def summary_docs(row):
    base = {
        "sqlite_id": row["id"],
        "doc_type": "session_summary",
        "memory_session_id": row["memory_session_id"],
        "project": row["project"],
        "merged_into_project": row["merged_into_project"],
        "platform_source": normalize_platform_source(row["platform_source"]),
        "created_at_epoch": row["created_at_epoch"],
        "prompt_number": row["prompt_number"] or 0,
    }
    return [
        (f"summary_{row['id']}_{field}", row[field], clean({**base, "field_type": field}))
        for field in SUMMARY_FIELDS
        if row[field]
    ]


def prompt_docs(row):
    # formatUserPromptDoc does not normalize platform_source; the SQL COALESCE
    # already defaults it to 'claude'. Match that exactly.
    return [(
        f"prompt_{row['id']}",
        row["prompt_text"],
        clean({
            "sqlite_id": row["id"],
            "doc_type": "user_prompt",
            "memory_session_id": row["memory_session_id"],
            "project": row["project"],
            "platform_source": row["platform_source"],
            "created_at_epoch": row["created_at_epoch"],
            "prompt_number": row["prompt_number"],
        }),
    )] if row["prompt_text"] else []


QUERIES = (
    ("observations", observation_docs, """
        SELECT o.*, COALESCE(NULLIF(s.platform_source, ''), 'claude') AS platform_source
        FROM observations o
        LEFT JOIN sdk_sessions s ON s.memory_session_id = o.memory_session_id
        WHERE o.project IS NOT NULL AND o.project != ''
        ORDER BY o.id ASC
    """),
    ("summaries", summary_docs, """
        SELECT ss.*, COALESCE(NULLIF(s.platform_source, ''), 'claude') AS platform_source
        FROM session_summaries ss
        LEFT JOIN sdk_sessions s ON s.memory_session_id = ss.memory_session_id
        WHERE ss.project IS NOT NULL AND ss.project != ''
        ORDER BY ss.id ASC
    """),
    ("prompts", prompt_docs, """
        SELECT up.*, s.project, s.memory_session_id,
               COALESCE(NULLIF(s.platform_source, ''), 'claude') AS platform_source
        FROM user_prompts up
        JOIN sdk_sessions s ON up.session_db_id = s.id
        WHERE s.project IS NOT NULL AND s.project != ''
        ORDER BY up.id ASC
    """),
)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--apply", action="store_true", help="write to Chroma (default: plan only)")
    args = ap.parse_args()

    for path in (MEM_DB, CHROMA_DIR):
        if not os.path.exists(path):
            sys.exit(f"missing: {path}")

    import chromadb
    from chromadb.utils import embedding_functions

    client = chromadb.PersistentClient(path=CHROMA_DIR)
    collection = client.get_collection(
        COLLECTION, embedding_function=embedding_functions.DefaultEmbeddingFunction()
    )

    print(f"collection {COLLECTION}: {collection.count()} documents")

    print("reading existing document ids...", flush=True)
    existing = set()
    offset = 0
    while True:
        page = collection.get(limit=10000, offset=offset, include=[])
        ids = page["ids"]
        if not ids:
            break
        existing.update(ids)
        offset += len(ids)
    print(f"  {len(existing)} ids in Chroma")

    mem = sqlite3.connect(f"file:{MEM_DB}?mode=ro", uri=True)
    mem.row_factory = sqlite3.Row

    pending = []
    for label, formatter, sql in QUERIES:
        missing = 0
        for row in mem.execute(sql):
            for doc_id, text, metadata in formatter(row):
                if doc_id not in existing and text:
                    pending.append((doc_id, text, metadata))
                    missing += 1
        print(f"  {label}: {missing} documents missing")

    if not pending:
        print("nothing to repair")
        return

    print(f"total: {len(pending)} documents to embed")
    if not args.apply:
        print("plan only. re-run with --apply to write.")
        return

    started = time.monotonic()
    written = 0
    for i in range(0, len(pending), BATCH):
        chunk = pending[i:i + BATCH]
        collection.add(
            ids=[c[0] for c in chunk],
            documents=[c[1] for c in chunk],
            metadatas=[c[2] for c in chunk],
        )
        written += len(chunk)
        elapsed = time.monotonic() - started
        rate = written / elapsed if elapsed else 0
        print(f"  {written}/{len(pending)} ({rate:.0f} docs/s)", flush=True)

    print(f"wrote {written} documents in {time.monotonic() - started:.0f}s")
    print(f"collection now holds {collection.count()} documents")


if __name__ == "__main__":
    main()

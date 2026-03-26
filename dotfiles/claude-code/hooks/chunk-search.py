#!/usr/bin/env python3
import re
import sys


def chunk_around_keyword(text, keyword, window=400, max_chunks=5):
    matches = [m.start() for m in re.finditer(re.escape(keyword), text, re.IGNORECASE)]
    if not matches:
        return []

    chunks = []
    for pos in matches:
        start = max(0, pos - window)
        end = min(len(text), pos + len(keyword) + window)
        if chunks and start <= chunks[-1][1]:
            chunks[-1] = (chunks[-1][0], end)
        else:
            chunks.append((start, end))

    results = []
    for i, (s, e) in enumerate(chunks[:max_chunks]):
        prefix = '...' if s > 0 else ''
        suffix = '...' if e < len(text) else ''
        results.append(f'[chunk {i+1}/{min(len(chunks), max_chunks)}] {prefix}{text[s:e]}{suffix}')
    return results


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: chunk-search.py <keyword> [window_chars] [max_chunks]", file=sys.stderr)
        print("Reads plain text from stdin, outputs chunks around keyword matches.", file=sys.stderr)
        sys.exit(1)

    keyword = sys.argv[1]
    window = int(sys.argv[2]) if len(sys.argv) > 2 else 400
    max_chunks = int(sys.argv[3]) if len(sys.argv) > 3 else 5

    text = sys.stdin.read()
    for chunk in chunk_around_keyword(text, keyword, window, max_chunks):
        print(chunk)
        print()

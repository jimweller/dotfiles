#!/usr/bin/env python3
import json
import sys
from datetime import datetime
from pathlib import Path


def parse_conversation(jsonl_path, output_path, session_id="unknown", hook_event="unknown", reason="unknown"):
    with open(output_path, 'w') as outfile:
        outfile.write("# Conversation Transcript\n\n")
        outfile.write(f"**Session ID:** `{session_id}`\n")
        outfile.write(f"**Saved:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        outfile.write(f"**Event:** {hook_event}\n")
        outfile.write(f"**Reason:** {reason}\n\n---\n\n")

        with open(jsonl_path, 'r') as infile:
            for line in infile:
                try:
                    data = json.loads(line)
                    msg_type = data.get('type')
                    message = data.get('message', {})
                    role = message.get('role')

                    if msg_type == 'user' and role == 'user':
                        content = message.get('content')
                        if isinstance(content, list):
                            continue
                        if not content or 'Caveat:' in content:
                            continue
                        if '<command-name>' in content or '<local-command-stdout>' in content:
                            continue
                        outfile.write("## USER\n\n")
                        outfile.write(f"{content}\n\n")

                    elif msg_type == 'assistant' and role == 'assistant':
                        content_list = message.get('content', [])
                        if not isinstance(content_list, list):
                            continue

                        assistant_text = []
                        tool_uses = []

                        for item in content_list:
                            if item.get('type') == 'text':
                                text = item.get('text', '').strip()
                                if text:
                                    assistant_text.append(text)
                            elif item.get('type') == 'tool_use':
                                tool_name = item.get('name', 'unknown')
                                tool_input = item.get('input', {})
                                tool_uses.append((tool_name, tool_input))

                        if assistant_text or tool_uses:
                            outfile.write("## ASSISTANT\n\n")
                            for text in assistant_text:
                                outfile.write(f"{text}\n\n")
                            if tool_uses:
                                for tool_name, tool_input in tool_uses:
                                    outfile.write(f"**Tool:** `{tool_name}`\n")
                                    if tool_input:
                                        for key in ('file_path', 'pattern', 'command', 'prompt', 'description'):
                                            if key in tool_input:
                                                val = str(tool_input[key])
                                                if len(val) > 100:
                                                    val = val[:100] + '...'
                                                outfile.write(f"- {key}: `{val}`\n")
                                    outfile.write("\n")

                except json.JSONDecodeError:
                    continue
                except Exception as e:
                    print(f"Warning: {e}", file=sys.stderr)
                    continue


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: parse-conversation.py <input.jsonl> <output.md> [session_id] [hook_event] [reason]")
        sys.exit(1)

    parse_conversation(
        sys.argv[1],
        sys.argv[2],
        sys.argv[3] if len(sys.argv) > 3 else "unknown",
        sys.argv[4] if len(sys.argv) > 4 else "unknown",
        sys.argv[5] if len(sys.argv) > 5 else "unknown",
    )

#!/usr/bin/env bash
# Renders the per-subagent rows shown under the prompt while subagents run.
# Claude Code feeds one JSON object on stdin per refresh (about every 5s) and
# reads back newline-delimited {"id","content"} objects, one per row to restyle.
# Rows we omit keep the default rendering. TUI only; headless never calls this.
#
# Payload per task, from the binary's own builder: id, name, type, status,
# description, label, startTime (epoch ms), model, effort, contextWindowSize,
# tokenCount, tokenSamples, cwd. Top level adds session_id, transcript_path,
# cwd, prompt_id, columns, tasks.
#
# name and effort arrive as undefined for most agents and JSON drops undefined
# keys, so neither is reliably present. name is set only for agents held in the
# internal agentNameRegistry. tokenCount reads 0 until the agent's first API
# response lands, so the row takes the last tokenSamples entry instead.
#
# `columns` is the full terminal width. The drawn row sits inside a narrower
# cell, so ROW_MARGIN reserves space for the bullet and any trailing decoration.
# Widths are measured on uncoloured text before colour is applied, because ANSI
# escapes would otherwise count against the budget.
#
# Raw stdin is appended to ~/.logs/subagent-statusline.jsonl, which log-rotate.sh
# already caps, so the payload schema stays available for reference.

set -euo pipefail

ROW_MARGIN=12

payload=$(cat)
printf '%s\n' "$payload" >>"$HOME/.logs/subagent-statusline.jsonl" 2>/dev/null || true

command -v jq >/dev/null 2>&1 || exit 0

# The payload carries no agent type. Its `name` field is populated only for
# explicitly named background agents and is absent for every subagent_type,
# verified across two runs including a purpose-built `napper` agent. The type
# does live in the transcript, which the payload points at: an Agent tool_use
# carries input.subagent_type, and the matching tool_result carries agentId.
#
# Resolving that means parsing the transcript, so results are cached by agent id
# and each id is looked up once for its lifetime rather than every 5s tick.
TYPE_CACHE="$HOME/.cache/claude-subagent-types.tsv"
types_json='{}'

resolve_types() {
    local transcript ids unknown
    transcript=$(printf '%s' "$payload" | jq -r '.transcript_path // empty') || return 0
    [[ -n "$transcript" && -f "$transcript" ]] || return 0
    ids=$(printf '%s' "$payload" | jq -r '.tasks[]?.id') || return 0
    [[ -n "$ids" ]] || return 0

    mkdir -p "$(dirname "$TYPE_CACHE")" 2>/dev/null || return 0
    [[ -f "$TYPE_CACHE" ]] || : >"$TYPE_CACHE"

    unknown=$(comm -23 <(printf '%s\n' "$ids" | sort -u) \
                       <(cut -f1 "$TYPE_CACHE" | sort -u) 2>/dev/null) || unknown=""

    if [[ -n "$unknown" ]]; then
        python3 - "$transcript" "$TYPE_CACHE" <<'PY' 2>/dev/null || true
import json, sys
transcript, cache = sys.argv[1], sys.argv[2]
tool2type, found = {}, {}
with open(transcript, errors="replace") as fh:
    for line in fh:
        if '"Agent"' not in line and "agentId" not in line:
            continue
        try:
            rec = json.loads(line)
        except Exception:
            continue
        content = rec.get("message", {}).get("content")
        blocks = content if isinstance(content, list) else []
        for b in blocks:
            if isinstance(b, dict) and b.get("type") == "tool_use" and b.get("name") == "Agent":
                tool2type[b["id"]] = b.get("input", {}).get("subagent_type")
        result = rec.get("toolUseResult")
        if isinstance(result, dict) and "agentId" in result:
            tool_id = next((b.get("tool_use_id") for b in blocks
                            if isinstance(b, dict) and b.get("type") == "tool_result"), None)
            kind = tool2type.get(tool_id)
            if kind:
                found[result["agentId"]] = kind
if found:
    with open(cache, "a") as fh:
        for agent_id, kind in found.items():
            fh.write(f"{agent_id}\t{kind}\n")
PY
    fi

    # awk rather than another python3, because interpreter startup dominates a
    # tick that fires every 5 seconds.
    types_json=$(awk -F'\t' '
        BEGIN { printf "{" }
        NF == 2 && !seen[$1]++ {
            if (n++) printf ",";
            gsub(/"/, "", $1); gsub(/"/, "", $2);
            printf "\"%s\":\"%s\"", $1, $2
        }
        END { printf "}" }' "$TYPE_CACHE" 2>/dev/null) || types_json='{}'
    [[ -n "$types_json" ]] || types_json='{}'
}

resolve_types || true

printf '%s' "$payload" | jq -c --argjson margin "$ROW_MARGIN" --argjson types "$types_json" '
  def paint($c): "[\($c)m\(.)[0m";

  def elapsed:
    (. / 3600 | floor) as $h
    | (. % 3600 / 60 | floor) as $m
    | (. % 60 | floor) as $s
    | if $h > 0 then "\($h)h\($m)m\($s)s"
      elif $m > 0 then "\($m)m\($s)s"
      else "\($s)s" end;

  def commas:
    tostring | explode | reverse
    | [range(0; length) as $i
       | (.[$i], if ($i % 3 == 2 and $i + 1 < length) then 44 else empty end)]
    | reverse | implode;

  def clamp($w):
    if $w <= 0 then "" elif length > $w then .[0:$w-1] + "…" else . end;

  # Avoids leaning on a red/green split, which dark-daltonized does not separate.
  # Third element is the trailing separator the glyph carries, so the row skips
  # the usual two-space join after it. U+26A1 is East Asian Wide and draws in two
  # columns, the rest draw in one, and jq counts all of them as length 1. Giving
  # the wide bolt one space and the narrow glyphs two lands every title in the
  # same column without the bolt looking padded.
  def glyph:
    if . == "running" then ["⚡", "1;33", " "]
    elif . == "completed" then ["✓", "1;36", "  "]
    elif . == "failed" or . == "error" then ["✗", "1;31", "  "]
    elif . == "queued" or . == "pending" then ["○", "2;37", "  "]
    else ["●", "2;37", "  "] end;

  # Same letters statusline-command.sh uses, so the two bars read alike. That
  # script ramps brightness per level because it paints the cell as a
  # background. Here the letter sits in normal text and takes one colour.
  # Absent effort prints nothing rather than defaulting to low.
  def effortmark:
    if . == null then ""
    elif . == "low" then "l"
    elif . == "medium" then "m"
    elif . == "high" then "h"
    elif . == "xhigh" then "x"
    elif . == "max" then "m"
    elif startswith("ultra") then "u"
    else "" end;

  # claude-sonnet-5[1m] and global.anthropic.claude-haiku-4-5-2025... both reduce
  # to the family name.
  def shortmodel:
    if . == null then "-"
    else ascii_downcase
         | if test("fable") then "fable"
           elif test("opus") then "opus"
           elif test("sonnet") then "sonnet"
           elif test("haiku") then "haiku"
           else .[0:12] end
    end;

  ((.columns // 120) - $margin) as $width
  | (now * 1000) as $now
  | .tasks[]?
  | ((.status // "?") | glyph) as $g
  | (.label // .description // "-") as $title
  | (.description // "-") as $desc
  | (if $desc == $title then [] else [$desc] end) as $descpart
  | (.model | shortmodel) as $model
  | (.effort | effortmark) as $e
  | ((.name // $types[.id] // null) | if . == null then [] else [.] end) as $agentpart
  | ((.tokenSamples // [] | last // 0)) as $toknum
  | (if $toknum == 0 then "—" else ($toknum | commas) end) as $tokens
  | ((if ((.startTime // 0) > 0) then (($now - .startTime) / 1000) else 0 end)
     | if . < 0 then 0 else . end | elapsed) as $age
  # Lay the row out at full length, measure it, then take the overage out of the
  # shrinkable fields in priority order: description first, then agent type,
  # then title. Measuring beats pre-allocating, because the separator count
  # changes with which optional fields are present.
  | ($agentpart | first // "") as $agent0
  | ($descpart | first // "") as $desc0
  | (def plain($t; $a; $d):
       # The glyph cell always draws 3 columns: a 2-column wide glyph plus one
       # space, or a 1-column glyph plus two. jq measures the wide one as 1, so
       # the constant is used instead of a length.
       3 +
       ([$t, $model, $e, $a, $d, $tokens, $age]
        | map(select(. != "")) | join("  ") | length);
     plain($title; $agent0; $desc0) - $width) as $over
  | (if $over <= 0 then $desc0
     else ($desc0 | clamp(($desc0 | length) - $over)) end) as $desctext
  | ($over - (($desc0 | length) - ($desctext | length))) as $over2
  | (if $over2 <= 0 then $agent0
     else ($agent0 | clamp(($agent0 | length) - $over2)) end) as $agenttext
  | ($over2 - (($agent0 | length) - ($agenttext | length))) as $over3
  | (if $over3 <= 0 then $title
     else ($title | clamp(($title | length) - $over3)) end) as $titletext
  | {
      id,
      content: (($g[0] | paint($g[1])) + $g[2]) + ([
        (if $titletext == "" then empty else $titletext end),
        ($model | paint("36")),
        (if ($e | length) == 0 then empty else ($e | paint("33")) end),
        (if $agenttext == "" then empty else ($agenttext | paint("35")) end),
        (if $desctext == "" then empty else ($desctext | paint("2;37")) end),
        (if $toknum == 0 then ($tokens | paint("2;37")) else ($tokens | paint("1;37")) end),
        ($age | paint("2;37"))
      ] | map(select(. != "")) | join("  "))
    }
' 2>/dev/null || exit 0

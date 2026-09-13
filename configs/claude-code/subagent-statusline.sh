#!/usr/bin/env bash
# Renders the per-subagent rows shown under the prompt while subagents run.
# Claude Code feeds one JSON object on stdin per refresh (about every 5s) and
# reads back newline-delimited {"id","content"} objects, one per row to restyle.
# Rows we omit keep the default rendering. TUI only; headless never calls this.
#
# Per-task fields on stdin: id, type, status, description, label, startTime
# (epoch ms), model, contextWindowSize, tokenCount, tokenSamples, cwd. Top level
# carries session_id, transcript_path, cwd, prompt_id, columns, tasks.
# tokenCount stays 0 until the agent's first API response lands, so the row
# reads the last tokenSamples entry instead.
#
# `columns` is the full terminal width. The row Claude Code draws sits inside a
# narrower cell (it subtracts a prefix), so ROW_MARGIN keeps the text clear of
# the bullet and any trailing decoration.
#
# Narrow terminals shrink label and description first. Status, model, tokens and
# elapsed stay whole, because those are the fields worth reading when deciding
# whether an agent is stuck or burning context.
#
# Raw stdin is appended to ~/.logs/subagent-statusline.jsonl, which log-rotate.sh
# already caps, so the payload schema stays available for reference.

set -euo pipefail

ROW_MARGIN=12

payload=$(cat)
printf '%s\n' "$payload" >>"$HOME/.logs/subagent-statusline.jsonl" 2>/dev/null || true

command -v jq >/dev/null 2>&1 || exit 0

printf '%s' "$payload" | jq -c --argjson margin "$ROW_MARGIN" '
  def elapsed:
    (. / 3600 | floor) as $h
    | (. % 3600 / 60 | floor) as $m
    | (. % 60 | floor) as $s
    | if $h > 0 then "\($h)h\($m)m\($s)s"
      elif $m > 0 then "\($m)m\($s)s"
      else "\($s)s" end;
  def commas:
    tostring
    | explode | reverse
    | [range(0; length) as $i | (.[$i], if ($i % 3 == 2 and $i + 1 < length) then 44 else empty end)]
    | reverse | implode;
  def clamp($w):
    if $w <= 0 then ""
    elif length > $w then .[0:$w-1] + "…"
    else . end;
  ((.columns // 120) - $margin) as $width
  | (now * 1000) as $now
  | .tasks[]?
  | (.label // "-") as $label
  | (.description // "-") as $desc
  | (if $desc == $label then [] else [$desc] end) as $descpart
  | (.status // "?") as $status
  | (.model // "-") as $model
  | ((.tokenSamples // [] | last // 0) | commas) as $tokens
  # A missing or zero startTime would otherwise date the agent to the epoch.
  | ((if ((.startTime // 0) > 0) then (($now - .startTime) / 1000) else 0 end)
     | if . < 0 then 0 else . end | elapsed) as $age
  # Fixed columns plus the two-space separators between every field.
  | (($status | length) + ($model | length) + ($tokens | length) + ($age | length)
     + (2 * (4 + ($descpart | length)))) as $fixed
  | ($width - $fixed) as $free
  # Label takes only what it needs, capped at half; the description gets the rest.
  | (if ($descpart | length) == 0 then $free
     else ([($label | length), ($free / 2 | floor)] | min) end) as $labelroom
  | ($label | clamp($labelroom)) as $labeltext
  | {
      id,
      content: ([
        $status,
        $labeltext,
        $model,
        ($descpart[]? | clamp($free - ($labeltext | length))),
        $tokens,
        $age
      ] | map(select(. != "")) | join("  ") | clamp($width))
    }
' 2>/dev/null || exit 0

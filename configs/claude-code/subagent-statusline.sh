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

printf '%s' "$payload" | jq -c --argjson margin "$ROW_MARGIN" '
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
  def glyph:
    if . == "running" then ["⚡", "1;33"]
    elif . == "completed" then ["✓", "1;36"]
    elif . == "failed" or . == "error" then ["✗", "1;31"]
    elif . == "queued" or . == "pending" then ["○", "2;37"]
    else ["●", "2;37"] end;

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
  | (if .name == null then [] else [.name] end) as $agentpart
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
       [$g[0], $t, $model, $e, $a, $d, $tokens, $age]
       | map(select(. != "")) | join("  ") | length;
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
      content: ([
        ($g[0] | paint($g[1])),
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

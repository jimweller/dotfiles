#!/usr/bin/env bash
set -euo pipefail

PHASE1_DIR="$1"

ENTITIES_FILE="$PHASE1_DIR/entities.jsonl"
CALLGRAPH_FILE="$PHASE1_DIR/callgraph.csv"
WORKLIST_FILE="$PHASE1_DIR/worklist.json"
FLAT_FILE="$PHASE1_DIR/_flat_worklist.tsv"
CLUSTER_FILE="$PHASE1_DIR/_cluster_assignments.tsv"

# ============================================================
# Phase A: Entity-grep cross-reference -> flat worklist TSV
#
# Uses awk with a basename hash index for O(n+m) matching
# instead of the previous O(n*m) bash loop.
# ============================================================

ENTITIES_TSV="$PHASE1_DIR/_entities.tsv"

# Extract entities to TSV in a single jq call
jq -r '[.file, (.line|tostring), .kind, .name, (.className // .name)] | @tsv' \
  "$ENTITIES_FILE" > "$ENTITIES_TSV"

# Cross-reference entities with grep hits, compute fan-in, output flat worklist
awk -v entsfile="$ENTITIES_TSV" \
    -v cg="$CALLGRAPH_FILE" \
'
BEGIN {
    OFS = "\t"

    # Read callgraph for fan-in counts
    if (cg != "") {
        while ((getline cgline < cg) > 0) {
            n = split(cgline, f, "|")
            if (n >= 4) {
                key = f[3] "." f[4]
                fan_in[key]++
            }
        }
        close(cg)
    }

    # Read entities TSV, index by file basename
    ent_count = 0
    while ((getline entline < entsfile) > 0) {
        ent_count++
        split(entline, ef, "\t")
        ent_file[ent_count] = ef[1]
        ent_line[ent_count] = ef[2] + 0
        ent_kind[ent_count] = ef[3]
        ent_name[ent_count] = ef[4]
        ent_class[ent_count] = ef[5]

        np = split(ef[1], parts, "/")
        bn = parts[np]
        if (bn in basename_ents)
            basename_ents[bn] = basename_ents[bn] " " ent_count
        else
            basename_ents[bn] = ent_count
    }
    close(entsfile)
}

# Process grep-*.txt files
{
    # Extract focus area from filename once per file
    if (FILENAME != _prev_file) {
        _prev_file = FILENAME
        _focus = FILENAME
        sub(/.*\/grep-/, "", _focus)
        sub(/\.txt$/, "", _focus)
    }

    # Parse grep line: /abs/path/file:line:content
    colon1 = index($0, ":")
    if (colon1 == 0) next
    hitfile = substr($0, 1, colon1 - 1)
    rest = substr($0, colon1 + 1)
    colon2 = index(rest, ":")
    if (colon2 == 0) next
    hitline = substr(rest, 1, colon2 - 1) + 0
    if (hitline <= 0) next

    # Match by basename
    np = split(hitfile, parts, "/")
    hit_bn = parts[np]
    if (!(hit_bn in basename_ents)) next

    # Find enclosing entity: largest start line <= hit line
    best_idx = -1
    best_line = -1
    n = split(basename_ents[hit_bn], candidates, " ")
    for (c = 1; c <= n; c++) {
        i = candidates[c] + 0
        if (i <= 0) continue
        el = ent_line[i]
        if (el <= hitline && el > best_line) {
            best_idx = i
            best_line = el
        }
    }

    if (best_idx > 0) {
        key = best_idx SUBSEP _focus
        hit_counts[key]++
    }
}

END {
    for (key in hit_counts) {
        split(key, kp, SUBSEP)
        i = kp[1] + 0
        focus = kp[2]
        hc = hit_counts[key]

        name = ent_name[i]
        kind = ent_kind[i]
        file = ent_file[i]
        line = ent_line[i]
        cls = ent_class[i]

        if (kind == "method")
            entity_label = cls "." name
        else
            entity_label = name

        fi = fan_in[cls "." name] + 0
        pscore = hc * (fi + 1)

        dedup_key = entity_label SUBSEP focus
        if (dedup_key in seen) continue
        seen[dedup_key] = 1

        print entity_label, cls, kind, file, line, focus, hc, fi, pscore
    }
}
' "$PHASE1_DIR"/grep-*.txt > "$FLAT_FILE"

rm -f "$ENTITIES_TSV"

# ============================================================
# Phase B: Graph-based clustering via union-find
#
# Algorithm: For each focus area, find connected components in
# the call graph subgraph induced by worklist entities. Entities
# in the same component become one cluster. Singletons stay as
# individual tasks.
# ============================================================

awk -F'\t' -v cg="$CALLGRAPH_FILE" '
# --- Union-Find ---
function find(x,    r, t) {
  r = x
  while (uf[r] != r) r = uf[r]
  while (uf[x] != r) { t = uf[x]; uf[x] = r; x = t }
  return r
}
function unite(a, b,    ra, rb) {
  ra = find(a); rb = find(b)
  if (ra != rb) uf[ra] = rb
}

BEGIN {
  OFS = "\t"
  # Read callgraph.csv (passed as cg variable) to build edge list
  # Format: caller_class|caller_method|callee_class|callee_method|file|line
  while ((getline cgline < cg) > 0) {
    split(cgline, f, "|")
    caller_class = f[1]
    callee_class = f[3]
    if (caller_class != callee_class && caller_class != "_unknown_" && callee_class != "_unknown_") {
      edge_count++
      edge_from[edge_count] = caller_class
      edge_to[edge_count] = callee_class
    }
  }
  close(cg)
}

# Read flat worklist TSV
{
  entity = $1; cls = $2; kind = $3; file = $4; line = $5
  focus = $6; hit_count = $7; fan_in = $8; pscore = $9

  # Index: which classes appear in which focus areas
  idx = focus SUBSEP cls
  class_in_focus[idx] = 1

  # Store all entries indexed by row number
  row++
  r_entity[row] = entity; r_class[row] = cls; r_kind[row] = kind
  r_file[row] = file; r_line[row] = line; r_focus[row] = focus
  r_hits[row] = hit_count; r_fanin[row] = fan_in; r_pscore[row] = pscore

  # Track focus areas
  focuses[focus] = 1
}

END {
  # For each focus area, run union-find on the callgraph subgraph
  for (focus in focuses) {
    # Initialize union-find: each class is its own parent
    delete uf
    for (key in class_in_focus) {
      split(key, kp, SUBSEP)
      if (kp[1] == focus) {
        uf[kp[2]] = kp[2]
      }
    }

    # Unite classes connected by callgraph edges (both must be in this focus)
    for (e = 1; e <= edge_count; e++) {
      from_key = focus SUBSEP edge_from[e]
      to_key = focus SUBSEP edge_to[e]
      if ((from_key in class_in_focus) && (to_key in class_in_focus)) {
        unite(edge_from[e], edge_to[e])
      }
    }

    # Assign cluster roots for this focus
    for (key in class_in_focus) {
      split(key, kp, SUBSEP)
      if (kp[1] == focus) {
        focus_cluster[focus SUBSEP kp[2]] = find(kp[2])
      }
    }
  }

  # Assign cluster IDs to each row
  cluster_id = 0
  for (r = 1; r <= row; r++) {
    root = focus_cluster[r_focus[r] SUBSEP r_class[r]]
    ckey = r_focus[r] SUBSEP root
    if (!(ckey in cluster_map)) {
      cluster_id++
      cluster_map[ckey] = cluster_id
    }
    # Output: cluster_id \t original fields
    print cluster_map[ckey], r_entity[r], r_class[r], r_kind[r], r_file[r], r_line[r], r_focus[r], r_hits[r], r_fanin[r], r_pscore[r]
  }
}
' "$FLAT_FILE" > "$CLUSTER_FILE"

# ============================================================
# Phase C: Assemble clustered JSON from cluster assignments
# ============================================================

# Build call_chain strings per cluster from callgraph edges
# and assemble final worklist.json
jq -n -R '

def parse_tsv:
  split("\t") | {
    cluster_id: .[0],
    entity: .[1],
    class: .[2],
    kind: .[3],
    file: .[4],
    line: (.[5] | tonumber),
    focus: .[6],
    hit_count: (.[7] | tonumber),
    fan_in: (.[8] | tonumber),
    priority_score: (.[9] | tonumber)
  };

[inputs | parse_tsv]
| group_by(.cluster_id)
| map({
    cluster_id: (.[0].cluster_id | tonumber),
    focus: .[0].focus,
    entities: [.[] | {
      entity: .entity,
      kind: .kind,
      file: .file,
      line: .line,
      fan_in: .fan_in,
      hit_count: .hit_count
    }],
    priority_score: ([.[].priority_score] | add),
    call_chain: (
      if length == 1 then null
      else [.[].entity] | join(" -> ")
      end
    )
  })
| sort_by(-.priority_score)
' "$CLUSTER_FILE" > "$WORKLIST_FILE"

# Report stats
total_entries=$(wc -l < "$FLAT_FILE" | tr -d ' ')
cluster_count=$(jq 'length' "$WORKLIST_FILE")
multi_count=$(jq '[.[] | select(.entities | length > 1)] | length' "$WORKLIST_FILE")
singleton_count=$(jq '[.[] | select(.entities | length == 1)] | length' "$WORKLIST_FILE")

echo "Flat entries: $total_entries -> Clusters: $cluster_count (multi: $multi_count, singletons: $singleton_count)"

rm -f "$FLAT_FILE" "$CLUSTER_FILE"

#!/usr/bin/env bash
set -euo pipefail

PHASE1_DIR="$1"
WORKDIR="$2"
PROJECT_ROOT="$3"

CALLGRAPH_FILE="$PHASE1_DIR/callgraph.csv"
INHERITANCE_FILE="$PHASE1_DIR/inheritance.csv"
ENTITIES_FILE="$PHASE1_DIR/entities.jsonl"
OUTPUT_FILE="$WORKDIR/CLAUDE.md"
ENTITY_REF_FILE="$WORKDIR/entity-reference.md"
ENTITIES_TSV="$PHASE1_DIR/_entities_ref.tsv"

# --- Static review protocol ---
cat > "$OUTPUT_FILE" << 'STATIC_SECTION'
You are a code review agent. You do NOT write or modify source code.

For each task you receive, the named entities are your STARTING POINT, not
your boundary. Your goal is to understand each entity's place and role in the
codebase, then assess the cluster through the lens of the focus area.

## How to Navigate Code

Read entity-reference.md in this directory for class/method locations, call
relationships, and inheritance.

- Open files at the path and line shown in the Entity Reference
- Grep the target directory for class names, method names, and patterns
- Follow call chains using the callgraph file:line references
- Cite all findings using real file:line references

STATIC_SECTION

# Inject project root
cat >> "$OUTPUT_FILE" << EOF
Project root: $PROJECT_ROOT

EOF

# --- Dynamic entity reference table -> entity-reference.md ---

# Extract entities to TSV in a single jq call: kind, name, className, file, line
jq -r '[.kind, .name, (.className // .name), .file, (.line|tostring)] | @tsv' \
  "$ENTITIES_FILE" > "$ENTITIES_TSV"

# Build entity reference in awk: reads entities, inheritance, callgraph
awk -v entsfile="$ENTITIES_TSV" \
    -v inhfile="$INHERITANCE_FILE" \
    -v cgfile="$CALLGRAPH_FILE" \
'
BEGIN {
    # Read entities TSV
    class_count = 0
    while ((getline entline < entsfile) > 0) {
        split(entline, ef, "\t")
        kind = ef[1]; name = ef[2]; cls = ef[3]; file = ef[4]; line = ef[5]

        if (kind == "class") {
            if (!(name in class_seen)) {
                class_count++
                class_order[class_count] = name
                class_seen[name] = 1
                # Use basename:line for display
                np = split(file, parts, "/")
                class_file[name] = parts[np] ":" line
            }
        } else if (kind == "method") {
            np = split(file, parts, "/")
            entry = name " (" parts[np] ":" line ")"
            if (cls in class_methods)
                class_methods[cls] = class_methods[cls] ", " entry
            else
                class_methods[cls] = entry
        }
    }
    close(entsfile)

    # Read inheritance.csv: child|parent
    if (inhfile != "") {
        while ((getline inhline < inhfile) > 0) {
            n = split(inhline, f, "|")
            if (n < 2) continue
            child = f[1]; parent = f[2]
            if (child == "") continue
            if (child in class_inherits)
                class_inherits[child] = class_inherits[child] ", " parent
            else
                class_inherits[child] = parent
        }
        close(inhfile)
    }

    # Read callgraph.csv: caller_class|caller_method|callee_class|callee_method|file|line
    if (cgfile != "") {
        while ((getline cgline < cgfile) > 0) {
            n = split(cgline, f, "|")
            if (n < 4) continue
            caller = f[1]; callee = f[3]
            if (caller == "" || caller == callee || callee == "_unknown_") continue

            # Calls out (deduplicated by class pair)
            out_key = caller SUBSEP callee
            if (!(out_key in seen_out)) {
                seen_out[out_key] = 1
                if (caller in calls_out)
                    calls_out[caller] = calls_out[caller] ", " callee
                else
                    calls_out[caller] = callee
            }

            # Called by (deduplicated by class pair)
            by_key = callee SUBSEP caller
            if (!(by_key in seen_by)) {
                seen_by[by_key] = 1
                if (callee in called_by)
                    called_by[callee] = called_by[callee] ", " caller
                else
                    called_by[callee] = caller
            }
        }
        close(cgfile)
    }

    # Output entity reference markdown
    print "# Entity Reference (auto-generated from Joern CPG)"
    print ""

    for (i = 1; i <= class_count; i++) {
        cls = class_order[i]

        if (cls in class_file)
            print "### " cls " (" class_file[cls] ")"
        else
            print "### " cls

        if (cls in class_inherits)
            print "- Inherits/Implements: " class_inherits[cls]
        if (cls in class_methods)
            print "- Methods: " class_methods[cls]
        if (cls in calls_out)
            print "- Calls out to: " calls_out[cls]
        if (cls in called_by)
            print "- Called by: " called_by[cls]

        print ""
    }
}
' > "$ENTITY_REF_FILE"

rm -f "$ENTITIES_TSV"

echo "entity-reference.md written: $ENTITY_REF_FILE"

# --- Investigation protocol ---
cat >> "$OUTPUT_FILE" << 'PROTOCOL'
## Investigation Protocol

### Step 1: Read the Entities

Read each entity's source in the cluster. Understand what it does, what
parameters it takes, what it returns, what state it touches.

### Step 2: Verify the Neighborhood

Consult the Entity Reference above for known relationships. Then read the
containing class/module to confirm and extend. What other methods live
alongside this entity? What fields and state does the class hold? What is
this class's responsibility in the system?

When the Entity Reference is present, steps 2-5 are VERIFICATION of known
relationships, not blind discovery. Start from the reference, then grep to
confirm and find anything the static analysis missed.

### Step 3: Trace Callers (upward)

The Entity Reference lists known callers. Read each call site. For each:
- What data does the caller pass in? Where did that data originate?
- Is the caller validating/sanitizing inputs before calling this entity?
- Follow the caller chain up to the entry point (page handler, endpoint,
  scheduled task, event handler).
- Note the full path from user input to this entity.
- Grep for additional callers the static analysis may have missed (dynamic
  dispatch, reflection, string-based invocation).

### Step 4: Trace Callees (downward)

The Entity Reference lists known callees. Read the entity body to confirm.
For each outbound call:
- What does it call and with what arguments?
- Follow each call down to the terminal operation (DB write, HTTP response,
  file I/O, external service call).
- Note the full path from this entity to the final side effect.

### Step 5: Understand Siblings and Alternatives

The Entity Reference lists known interface implementations and base classes.
- Are there other implementations of the same interface?
- Are there similar methods in the same class or neighboring classes?
- Is this entity part of a pattern (factory, strategy, template method)?
- How is the concrete implementation selected at runtime (DI, config,
  factory, service locator)?

### Step 6: Assess Through the Focus Area Lens

With the full context (callers, callees, siblings, runtime selection,
data flow), assess the entity cluster and its surrounding code through the
focus area specified in the task. Look for:
- Defects in the entities themselves
- Defects in how the entities are used by callers
- Defects in what the entities delegate to
- Interaction defects between entities in the cluster
- Systemic patterns (is this a one-off problem or does it repeat across
  the codebase?)

### Step 7: Write Findings

Append findings to the review document specified in the task. Do not remove
existing content. For each finding include:
- Severity: Critical / High / Medium / Low
- The entity and its role in the system
- Full call chain with file:line references (entry point -> entity -> terminal)
- Data flow from source to sink
- Whether isolated or systemic (instance count, similar patterns elsewhere)
- How the entity's context contributes to the issue

### Step 8: Note Discoveries

If tracing reveals new entities worth investigating that are NOT in your
current task, note them at the bottom of the review document under
"Discovered Entities" with a brief reason why they are interesting.

## Rules

- Do not create any files other than the review documents.
- Do not modify source code.
- The entities are anchors, not boundaries. Trace as far as needed.
- Prefer depth over breadth. One fully-traced finding is more valuable
  than ten surface observations.
PROTOCOL

echo "CLAUDE.md written: $OUTPUT_FILE"

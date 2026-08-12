#!/usr/bin/env bash
# Scan a file with the installed mcg-sensitive-canary rules and config.
#
#   canary-scan.sh <file>
#
# Exit 0  no findings, or the plugin is not installed
# Exit 2  findings, one line per rule on stdout as "<ruleId> x<count>"
# Exit 1  usage or runtime error
#
# The plugin ships hooks only, no CLI, and its install path carries the version
# number. The active version is resolved from installed_plugins.json so this
# keeps working across plugin updates.

set -euo pipefail

TARGET="${1:-}"
[ -n "$TARGET" ] || { echo "usage: canary-scan.sh <file>" >&2; exit 1; }
[ -f "$TARGET" ] || { echo "no such file: $TARGET" >&2; exit 1; }

REGISTRY="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/installed_plugins.json"
[ -f "$REGISTRY" ] || exit 0

ROOT=$(python3 - "$REGISTRY" <<'PY'
import json, sys
try:
    reg = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(0)
for key, entries in (reg.get("plugins") or {}).items():
    if key.startswith("mcg-sensitive-canary@"):
        for e in entries if isinstance(entries, list) else [entries]:
            p = e.get("installPath")
            if p:
                print(p)
                sys.exit(0)
PY
)

# Plugin absent. Nothing to scan against; that is not an error.
[ -n "$ROOT" ] && [ -d "$ROOT/src/lib" ] || exit 0

PROBE="$ROOT/.canary-scan-probe.ts"
cat > "$PROBE" <<'TS'
import fs from "node:fs";
import { scan } from "./src/lib/rules.ts";
import { applyConfig, loadConfig } from "./src/lib/config.ts";

const findings = applyConfig(
  scan(fs.readFileSync(process.argv[2], "utf8")),
  loadConfig(),
) as Array<{ ruleId?: string }>;

const counts = new Map<string, number>();
for (const f of findings) {
  const id = f.ruleId ?? "unknown";
  counts.set(id, (counts.get(id) ?? 0) + 1);
}
for (const [id, n] of counts) console.log(`${id} x${n}`);
process.exit(findings.length > 0 ? 2 : 0);
TS

trap 'rm -f "$PROBE" 2>/dev/null || true' EXIT

set +e
(cd "$ROOT" && node --experimental-strip-types "$PROBE" "$TARGET")
STATUS=$?
set -e

exit "$STATUS"

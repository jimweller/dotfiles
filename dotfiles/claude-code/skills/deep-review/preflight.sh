#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="$1"
JOERN_FRONTEND="$2"

VALID_FRONTENDS="csharpsrc javasrc pythonsrc jssrc gosrc newc cppsrc"
ERRORS=0

pass() { printf "  PASS  %s\n" "$1"; }
fail() { printf "  FAIL  %s\n" "$1"; ERRORS=$((ERRORS + 1)); }

echo "=== Preflight checks ==="

# --- Required binaries ---
for bin in java joern joern-parse jq awk grep node npx aws; do
  if command -v "$bin" >/dev/null 2>&1; then
    pass "$bin on PATH"
  else
    fail "$bin not found on PATH"
  fi
done

# --- Minimum versions ---

java_raw=$(java -version 2>&1 | head -1 || true)
java_version=$(echo "$java_raw" | sed -n 's/.*"\([0-9][0-9]*\).*/\1/p')
if [ -n "$java_version" ] && [ "$java_version" -ge 11 ] 2>/dev/null; then
  pass "java >= 11 (found $java_version)"
else
  fail "java >= 11 required (found ${java_version:-none})"
fi

node_version=$(node --version 2>/dev/null | sed 's/^v//' | cut -d. -f1 || echo "0")
if [ "${node_version:-0}" -ge 18 ] 2>/dev/null; then
  pass "node >= 18 (found $node_version)"
else
  fail "node >= 18 required (found ${node_version:-unknown})"
fi

bash_major=$(echo "${BASH_VERSION}" | cut -d. -f1)
if [ "${bash_major:-0}" -ge 5 ] 2>/dev/null; then
  pass "bash >= 5 (found $BASH_VERSION)"
else
  fail "bash >= 5 required (found ${BASH_VERSION:-unknown})"
fi

jq_version=$(jq --version 2>/dev/null | sed 's/jq-//' || echo "0.0")
jq_major=$(echo "$jq_version" | cut -d. -f1)
jq_minor=$(echo "$jq_version" | cut -d. -f2)
if [ "${jq_major:-0}" -ge 1 ] && [ "${jq_minor:-0}" -ge 6 ] 2>/dev/null; then
  pass "jq >= 1.6 (found $jq_version)"
else
  fail "jq >= 1.6 required (found ${jq_version:-unknown})"
fi

# --- ralphy and opencode on PATH ---
for bin in ralphy opencode; do
  if command -v "$bin" >/dev/null 2>&1; then
    pass "$bin on PATH"
  else
    fail "$bin not found on PATH"
  fi
done

# --- AWS credentials (required for Bedrock models) ---
if aws sts get-caller-identity >/dev/null 2>&1; then
  pass "AWS credentials valid"
else
  fail "AWS credentials not configured (required for amazon-bedrock models)"
fi

# --- Target directory ---
if [ -d "$TARGET_DIR" ]; then
  pass "target directory exists: $TARGET_DIR"
else
  fail "target directory does not exist: $TARGET_DIR"
fi

# --- Joern frontend ---
if echo "$VALID_FRONTENDS" | grep -qw "$JOERN_FRONTEND"; then
  pass "Joern frontend valid: $JOERN_FRONTEND"
else
  fail "Joern frontend invalid: $JOERN_FRONTEND (must be one of: $VALID_FRONTENDS)"
fi

echo ""
if [ "$ERRORS" -gt 0 ]; then
  echo "FAILED: $ERRORS check(s) failed. See .claude/skills/deep-review/README.md for prerequisites."
  exit 1
fi
echo "All checks passed."

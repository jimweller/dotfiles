#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

LOG_FILE="$HOME/.logs/ccusage-cache-refresh.log"
CCUSAGE_CACHE="/tmp/ccusage-cache.json"
AZURE_CACHE="/tmp/azure-cost-cache.json"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
  local level="$1"
  shift
  printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" >> "$LOG_FILE"
}

log INFO "refresh started (ccusage $(npx ccusage --version 2>/dev/null || echo unknown))"

if npx ccusage claude daily --instances --json > "${CCUSAGE_CACHE}.tmp" 2> "${CCUSAGE_CACHE}.err"; then
  mv "${CCUSAGE_CACHE}.tmp" "$CCUSAGE_CACHE"
  log INFO "ccusage cache updated ($(wc -c < "$CCUSAGE_CACHE" | tr -d ' ') bytes)"
else
  rc=$?
  log ERROR "ccusage failed (exit $rc): $(head -3 "${CCUSAGE_CACHE}.err" | tr '\n' ' ')"
  rm -f "${CCUSAGE_CACHE}.tmp"
fi
rm -f "${CCUSAGE_CACHE}.err"

SUB="3e4bd6d0-9adb-4fa7-bb8f-0ebd20c99aa9"
RG="dxclinical-187aa68e-rg"
ACCOUNT_ID="/subscriptions/${SUB}/resourceGroups/${RG}/providers/Microsoft.CognitiveServices/accounts/dxclinical-187aa68e"
API_URL="https://management.azure.com/subscriptions/${SUB}/providers/Microsoft.CostManagement/query?api-version=2023-11-01"
# Cost Management reports cost per UTC day and ingests usage hours late, so its
# newest day is partial. The day before it is the last fully billed day. Every Azure
# cost and token figure ends there, so $/MTok compares the same usage.
TODAY_UTC=$(date -u +%Y-%m-%d)
LOOKBACK_UTC=$(date -u -v-60d +%Y-%m-%d)

DAILY_BODY="{
  \"type\": \"Usage\",
  \"timeframe\": \"Custom\",
  \"timePeriod\": { \"from\": \"${LOOKBACK_UTC}\", \"to\": \"${TODAY_UTC}\" },
  \"dataset\": {
    \"granularity\": \"Daily\",
    \"aggregation\": { \"totalCost\": { \"name\": \"Cost\", \"function\": \"Sum\" } },
    \"filter\": { \"dimensions\": { \"name\": \"ResourceGroup\", \"operator\": \"In\", \"values\": [\"${RG}\"] } }
  }
}"

azure_daily_cost() {
  local raw rows
  if ! raw=$(timeout 30 az rest --method post --url "$API_URL" --headers "ClientType=ccusage-statusline" --body "$DAILY_BODY" 2>&1); then
    log ERROR "azure cost query failed: $(printf '%s' "$raw" | head -1)"
    return 1
  fi
  if ! rows=$(printf '%s' "$raw" | jq -e -c '[.properties.rows[] | (.[1] | tostring) as $d
      | {day: ($d[0:4] + "-" + $d[4:6] + "-" + $d[6:8]), cost: .[0]}]' 2>/dev/null); then
    log ERROR "azure: no cost rows in response: $(printf '%s' "$raw" | head -c 200 | tr '\n' ' ')"
    return 1
  fi
  printf '%s' "$rows"
}

azure_daily_tokens() {
  local start="$1" end="$2" raw rows
  if ! raw=$(timeout 60 az monitor metrics list --resource "$ACCOUNT_ID" \
    --metrics InputTokens OutputTokens ephemeral5mInputTokens ephemeral1hInputTokens cacheReadInputTokens \
    --aggregation Total --interval P1D --start-time "${start}T00:00:00Z" --end-time "${end}T00:00:00Z" -o json 2>&1); then
    log ERROR "azure tokens query failed: $(printf '%s' "$raw" | head -1)"
    return 1
  fi
  if ! rows=$(printf '%s' "$raw" | jq -e -c '[.value[].timeseries[].data[] | {day: .timeStamp[0:10], tokens: (.total // 0)}]' 2>/dev/null); then
    log ERROR "azure: no token data in response: $(printf '%s' "$raw" | head -c 200 | tr '\n' ' ')"
    return 1
  fi
  printf '%s' "$rows"
}

BILLED=""
COST_ROWS=$(azure_daily_cost) || COST_ROWS=""
if [[ -n "$COST_ROWS" ]]; then
  NEWEST=$(printf '%s' "$COST_ROWS" | jq -r '[.[] | select(.cost > 0) | .day] | max // empty')
  if [[ -n "$NEWEST" ]]; then
    BILLED=$(date -u -j -v-1d -f %Y-%m-%d "$NEWEST" +%Y-%m-%d)
  else
    log ERROR "azure: no billed day since $LOOKBACK_UTC"
  fi
fi

if [[ -n "$BILLED" ]]; then
  MTD_START="${BILLED:0:7}-01"
  ROLLING_START=$(date -u -j -v-29d -f %Y-%m-%d "$BILLED" +%Y-%m-%d)
  WINDOW_START=$(printf '%s\n' "$MTD_START" "$ROLLING_START" | sort | head -1)
  if [[ "$WINDOW_START" < "$LOOKBACK_UTC" ]]; then
    log ERROR "azure: last billed day $BILLED needs cost rows before the $LOOKBACK_UTC lookback"
    BILLED=""
  fi
fi

if [[ -n "$BILLED" ]]; then
  TOKENS_END=$(date -u -j -v+1d -f %Y-%m-%d "$BILLED" +%Y-%m-%d)
  TOKEN_ROWS=$(azure_daily_tokens "$WINDOW_START" "$TOKENS_END") || TOKEN_ROWS="null"
  if jq -n --argjson cost "$COST_ROWS" --argjson tokens "$TOKEN_ROWS" \
    --arg billed "$BILLED" --arg mtd "$MTD_START" --arg rolling "$ROLLING_START" '
    def total($rows; $key; $from): [$rows[] | select(.day >= $from and .day <= $billed) | .[$key]] | add // 0;
    {mtd: total($cost; "cost"; $mtd), rolling30d: total($cost; "cost"; $rolling)}
    + (if $tokens then {mtdTokens: total($tokens; "tokens"; $mtd), rolling30dTokens: total($tokens; "tokens"; $rolling)} else {} end)' \
    > "${AZURE_CACHE}.tmp"; then
    mv "${AZURE_CACHE}.tmp" "$AZURE_CACHE"
    log INFO "azure cache updated through $BILLED: $(jq -c . "$AZURE_CACHE")"
  else
    log ERROR "azure cache write failed"
    rm -f "${AZURE_CACHE}.tmp"
  fi
else
  log WARN "azure cache not updated"
fi

log INFO "refresh finished"

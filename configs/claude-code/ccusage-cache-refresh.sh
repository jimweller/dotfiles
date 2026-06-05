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

if npx ccusage daily -i --json > "${CCUSAGE_CACHE}.tmp" 2> "${CCUSAGE_CACHE}.err"; then
  mv "${CCUSAGE_CACHE}.tmp" "$CCUSAGE_CACHE"
  log INFO "ccusage cache updated ($(wc -c < "$CCUSAGE_CACHE" | tr -d ' ') bytes)"
else
  rc=$?
  log ERROR "ccusage failed (exit $rc): $(head -3 "${CCUSAGE_CACHE}.err" | tr '\n' ' ')"
  rm -f "${CCUSAGE_CACHE}.tmp"
fi
rm -f "${CCUSAGE_CACHE}.err"

SUB="3e4bd6d0-9adb-4fa7-bb8f-0ebd20c99aa9"
RG="mcg-devx-clinical-ai-foundry"
API_URL="https://management.azure.com/subscriptions/${SUB}/providers/Microsoft.CostManagement/query?api-version=2023-11-01"
DATE_30D=$(date -v-30d +%Y-%m-%d)
DATE_TODAY=$(date +%Y-%m-%d)

azure_query() {
  local label="$1" body="$2" raw cost
  if ! raw=$(az rest --method post --url "$API_URL" --headers "ClientType=ccusage-statusline" --body "$body" 2>&1); then
    log ERROR "azure $label query failed: $(printf '%s' "$raw" | head -1)"
    return 1
  fi
  if ! cost=$(printf '%s' "$raw" | jq -e -r '.properties.rows[0][0]' 2>/dev/null); then
    log ERROR "azure $label: no cost in response: $(printf '%s' "$raw" | head -c 200 | tr '\n' ' ')"
    return 1
  fi
  log INFO "azure $label = $cost"
  printf '%s' "$cost"
}

MTD_BODY="{
  \"type\": \"Usage\",
  \"timeframe\": \"MonthToDate\",
  \"dataset\": {
    \"granularity\": \"None\",
    \"aggregation\": { \"totalCost\": { \"name\": \"Cost\", \"function\": \"Sum\" } },
    \"filter\": { \"dimensions\": { \"name\": \"ResourceGroup\", \"operator\": \"In\", \"values\": [\"${RG}\"] } }
  }
}"

ROLLING_BODY="{
  \"type\": \"Usage\",
  \"timeframe\": \"Custom\",
  \"timePeriod\": { \"from\": \"${DATE_30D}\", \"to\": \"${DATE_TODAY}\" },
  \"dataset\": {
    \"granularity\": \"None\",
    \"aggregation\": { \"totalCost\": { \"name\": \"Cost\", \"function\": \"Sum\" } },
    \"filter\": { \"dimensions\": { \"name\": \"ResourceGroup\", \"operator\": \"In\", \"values\": [\"${RG}\"] } }
  }
}"

MTD_COST=$(azure_query MTD "$MTD_BODY") || MTD_COST=""
ROLLING_COST=$(azure_query rolling30d "$ROLLING_BODY") || ROLLING_COST=""

if [[ -n "$MTD_COST" && -n "$ROLLING_COST" ]]; then
  if jq -n --argjson mtd "$MTD_COST" --argjson rolling "$ROLLING_COST" \
    '{mtd: $mtd, rolling30d: $rolling}' > "${AZURE_CACHE}.tmp"; then
    mv "${AZURE_CACHE}.tmp" "$AZURE_CACHE"
    log INFO "azure cache updated (mtd=$MTD_COST rolling30d=$ROLLING_COST)"
  else
    log ERROR "azure cache write failed"
    rm -f "${AZURE_CACHE}.tmp"
  fi
else
  log WARN "azure cache not updated (mtd='${MTD_COST}' rolling30d='${ROLLING_COST}')"
fi

log INFO "refresh finished"

#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

npx ccusage daily -i --json > /tmp/ccusage-cache.json.tmp 2>/dev/null && mv /tmp/ccusage-cache.json.tmp /tmp/ccusage-cache.json

SUB="3e4bd6d0-9adb-4fa7-bb8f-0ebd20c99aa9"
RG="mcg-devx-clinical-ai-foundry"
API_URL="https://management.azure.com/subscriptions/${SUB}/providers/Microsoft.CostManagement/query?api-version=2023-11-01"
DATE_30D=$(date -v-30d +%Y-%m-%d 2>/dev/null)
DATE_TODAY=$(date +%Y-%m-%d 2>/dev/null)

MTD_COST=$(az rest --method post --url "$API_URL" --body "{
  \"type\": \"Usage\",
  \"timeframe\": \"MonthToDate\",
  \"dataset\": {
    \"granularity\": \"None\",
    \"aggregation\": { \"totalCost\": { \"name\": \"Cost\", \"function\": \"Sum\" } },
    \"filter\": { \"dimensions\": { \"name\": \"ResourceGroup\", \"operator\": \"In\", \"values\": [\"${RG}\"] } }
  }
}" 2>/dev/null | jq '.properties.rows[0][0] // 0')

ROLLING_COST=$(az rest --method post --url "$API_URL" --body "{
  \"type\": \"Usage\",
  \"timeframe\": \"Custom\",
  \"timePeriod\": { \"from\": \"${DATE_30D}\", \"to\": \"${DATE_TODAY}\" },
  \"dataset\": {
    \"granularity\": \"None\",
    \"aggregation\": { \"totalCost\": { \"name\": \"Cost\", \"function\": \"Sum\" } },
    \"filter\": { \"dimensions\": { \"name\": \"ResourceGroup\", \"operator\": \"In\", \"values\": [\"${RG}\"] } }
  }
}" 2>/dev/null | jq '.properties.rows[0][0] // 0')

jq -n --argjson mtd "${MTD_COST:-0}" --argjson rolling "${ROLLING_COST:-0}" \
  '{mtd: $mtd, rolling30d: $rolling}' > /tmp/azure-cost-cache.json.tmp \
  && mv /tmp/azure-cost-cache.json.tmp /tmp/azure-cost-cache.json

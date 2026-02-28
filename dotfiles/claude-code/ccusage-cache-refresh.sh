#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export HOME="${HOME:-/Users/jimweller}"
npx ccusage daily -i --json > /tmp/ccusage-cache.json.tmp 2>/dev/null && mv /tmp/ccusage-cache.json.tmp /tmp/ccusage-cache.json

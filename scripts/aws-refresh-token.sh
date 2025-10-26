#!/bin/bash

# AWS Temporary Credential Refresh Script
#
# Uses AWS SSO session tokens to periodically refresh short-lived temporary credentials,
# ensuring they're always available for applications. Intended to run as a scheduled job.
# The job interval should be less than temporary token lifetime (8h < 12h at my work).
#
# This script clears the CLI cache before calling export-credentials to force a fresh
# temporary token every time. No need to calculate difference between job interval and
# expiration duration.
#
# How this script works:
# - Clears CLI cache to force fresh token
# - Calls 'aws configure export-credentials' which:
#   - Uses accessToken to request new temporary credentials from STS
#   - If accessToken expired: Auto-renews it using refreshToken (transparent to script)
#   - Creates new CLI cache with result
# - Exports credentials to custom file for applications
# - Works automatically until client registration expires (90 days from 'aws sso login')
#
# Scheduling with launchd on MacOS:
#  Put plist file in: ~/Library/LaunchAgents/com.user.refreshawstoken.plist
#  The plist filename must match the key: <string>com.user.refreshawstoken</string>
#  Load: launchctl load ~/Library/LaunchAgents/com.user.refreshawstoken.plist
#  Unload: launchctl unload ~/Library/LaunchAgents/com.user.refreshawstoken.plist
#  (if you change the plist file you must unload/load to refresh the job)
#
#  Use StartCalendarInterval (not StartInterval) for reliable scheduled execution:
#  - StartInterval skips jobs if Mac sleeps through scheduled time (launchd.plist(5))
#  - StartCalendarInterval runs missed jobs on next wake:
#    "Unlike cron which skips job invocations when the computer is asleep, launchd
#     will start the job the next time the computer wakes up" - launchd.plist(5)
#  - User-level LaunchAgents can't wake Mac, but execute all missed jobs upon wake
#  - Recommended schedule: every hour (runs at minute 0 of each hour), that buys about 12 hours of sleep time
#  - Reference: https://apple.stackexchange.com/questions/473841/
#
# How AWS token caching works
#
# Client Registration (90 days)
#    Location: ~/.aws/sso/cache/*.json (separate file with clientId/clientSecret)
#    Created by: aws sso login
#    Contains: OIDC client credentials for AWS CLI
#    Expires: registrationExpiresAt field (90 days from creation)
#    Impact if expires: All tokens become invalid, must run 'aws sso login'
#
# SSO Session Tokens (stored together in same cache file)
#    Location: ~/.aws/sso/cache/*.json
#    Created by: aws sso login
#
#    accessToken (~1 hour):
#       Purpose: Proves identity to AWS SSO for requesting temporary credentials
#       Expires: expiresAt field (~1 hour after login)
#       Impact if expires: AWS CLI auto-renews using refreshToken (no user action)
#
#    refreshToken (bound to client registration):
#       Purpose: Auto-renews accessToken without user interaction
#       Expires: When client registration expires (registrationExpiresAt field)
#       Impact if expires: Must run 'aws sso login' to re-register
#       Note: Follows OAuth 2.0 spec where refresh tokens are bound to issuing client
#
# Temporary Access Token (12 hours, duration configured by AWS admins)
#    Location: ~/.aws/cli/cache/*.json
#    Created by: Any AWS CLI commands that make API calls (aws configure export-credentials)
#    Contains: AccessKeyId, SecretAccessKey, SessionToken
#    Used by: AWS CLI and SDKs for API calls
#    Impact if expires: AWS commands fail until refreshed
#
# Custom Export File (This script's output)
#    Location: ~/assets/aws/aws-token.json (configurable)
#    Purpose: Makes temporary token available to custom credential_process in aws profile config
#

# configuration - must use full paths for launchd
AWS_CMD="/opt/homebrew/bin/aws"
JQ_CMD="/opt/homebrew/bin/jq"
DATE_CMD="/opt/homebrew/bin/gdate" # use gnu date for portability (brew install coreutils)

AWS_PROFILE_NAME="mcg"
CREDS_DIR="$HOME/assets/aws"
CREDS_FILE="$CREDS_DIR/aws-token.json"
LOG_FILE="$CREDS_DIR/refresh.log"
CLI_CACHE_DIR="$HOME/.aws/cli/cache"

log() {
  echo "$($DATE_CMD +'%Y-%m-%d %T %Z'): $1" >> "$LOG_FILE"
}

# safely inspect JSON file and mask sensitive fields
log_json_metadata() {
  local file="$1"
  local label="$2"
  
  if [ ! -f "$file" ]; then
    log "$label: File not found"
    return
  fi
  
  log "$label: $(basename "$file")"
  
  # extract and mask sensitive fields with 5 asterisks, handling nested structures
  local content=$($JQ_CMD '
    # Recursively walk the JSON and mask sensitive fields at any depth
    walk(
      if type == "object" then
        if .accessToken then .accessToken = "*****" else . end |
        if .refreshToken then .refreshToken = "*****" else . end |
        if .clientSecret then .clientSecret = "*****" else . end |
        if .AccessKeyId then .AccessKeyId = "*****" else . end |
        if .SecretAccessKey then .SecretAccessKey = "*****" else . end |
        if .SessionToken then .SessionToken = "*****" else . end
      else
        .
      end
    )
  ' "$file" 2>/dev/null)
  
  if [ $? -eq 0 ]; then
    log "$content"
  else
    log "  ERROR: Failed to parse JSON"
  fi
}

mkdir -p "$CREDS_DIR"

log "==== AWS Token Refresh Started ===="

# inspect SSO cache files
SSO_CACHE_DIR="$HOME/.aws/sso/cache"
if [ -d "$SSO_CACHE_DIR" ]; then
  log "-- SSO Cache Files --"
  for sso_file in "$SSO_CACHE_DIR"/*.json; do
    if [ -f "$sso_file" ]; then
      log_json_metadata "$sso_file" "SSO Cache"
    fi
  done
else
  log "SSO cache directory not found: $SSO_CACHE_DIR"
fi

# inspect CLI cache files (before clearing)
if [ -d "$CLI_CACHE_DIR" ] && ls "$CLI_CACHE_DIR"/*.json > /dev/null 2>&1; then
  log "-- CLI Cache Files (before clearing) --"
  for cli_file in "$CLI_CACHE_DIR"/*.json; do
    if [ -f "$cli_file" ]; then
      log_json_metadata "$cli_file" "CLI Cache"
    fi
  done
fi

log "-- Starting Refresh Process --"

# clear CLI cache to force fresh temporary token
if [ -d "$CLI_CACHE_DIR" ] && ls "$CLI_CACHE_DIR"/*.json > /dev/null 2>&1; then
  log "Clearing AWS CLI cache to force new temporary token"
  rm -f "$CLI_CACHE_DIR"/*.json > /dev/null 2>&1
fi

# get fresh temporary token from AWS (uses SSO token to make STS call)
$AWS_CMD configure export-credentials --profile "$AWS_PROFILE_NAME" --output json > "$CREDS_FILE" 2>> "$LOG_FILE"

if [ $? -ne 0 ]; then
  log "ERROR: Failed to get temporary token"
  
  # diagnostic: show cache state at time of failure
  log "-- Cache State at Failure --"
  if [ -d "$SSO_CACHE_DIR" ]; then
    for sso_file in "$SSO_CACHE_DIR"/*.json; do
      if [ -f "$sso_file" ]; then
        log_json_metadata "$sso_file" "SSO Cache"
      fi
    done
  fi
  
  if [ -d "$CLI_CACHE_DIR" ] && ls "$CLI_CACHE_DIR"/*.json > /dev/null 2>&1; then
    for cli_file in "$CLI_CACHE_DIR"/*.json; do
      if [ -f "$cli_file" ]; then
        log_json_metadata "$cli_file" "CLI Cache"
      fi
    done
  fi
  
  log "ACTION REQUIRED: Run 'aws sso login --profile $AWS_PROFILE_NAME' to re-authenticate"
  log "==== AWS Token Refresh Failed ===="
  exit 1
fi

# calculate and log expiration details
EXPIRATION=$($JQ_CMD -r .Expiration "$CREDS_FILE" 2>/dev/null)
current_epoch=$($DATE_CMD +"%s")
exp_str_fixed="${EXPIRATION%+00:00}Z" # AWS uses timezone offset, GNU date uses Z suffix
expiration_epoch=$($DATE_CMD -d "$exp_str_fixed" +"%s" 2>/dev/null)
seconds_remaining=$((expiration_epoch - current_epoch))

# convert seconds to HH:MM:SS using GNU date command
time_remaining=$($DATE_CMD -u -d "@$seconds_remaining" +"%Hh %Mm %Ss")

log "Successfully refreshed. Expiration: $EXPIRATION (${time_remaining} remaining)"

# inspect cache files after refresh to see what changed
log "-- Post-Refresh Cache State --"

if [ -d "$SSO_CACHE_DIR" ]; then
  log "SSO Cache Files (after refresh):"
  for sso_file in "$SSO_CACHE_DIR"/*.json; do
    if [ -f "$sso_file" ]; then
      log_json_metadata "$sso_file" "SSO Cache"
    fi
  done
fi

if [ -d "$CLI_CACHE_DIR" ] && ls "$CLI_CACHE_DIR"/*.json > /dev/null 2>&1; then
  log "CLI Cache Files (after refresh):"
  for cli_file in "$CLI_CACHE_DIR"/*.json; do
    if [ -f "$cli_file" ]; then
      log_json_metadata "$cli_file" "CLI Cache"
    fi
  done
else
  log "No CLI cache files after refresh"
fi

log "==== AWS Token Refresh Complete ===="

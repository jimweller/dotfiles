#!/bin/bash

# AWS Temporary Credential Refresh Script
#
# Uses AWS SSO session to periodically mint fresh short-lived temporary credentials.
# This script extends the availability of temporary credentials but CANNOT extend the
# SSO session itself - periodic re-authentication (aws sso login) is still required.
#
# How this script works:
# - Clears CLI cache to force fresh temporary credentials
# - Calls 'aws configure export-credentials' which:
#   - Uses refreshToken to get fresh accessToken (if needed)
#   - Uses accessToken to request new temporary IAM credentials from STS
#   - Creates new CLI cache with 12-hour credentials
# - Exports credentials to custom file for applications
# - Works automatically ONLY while SSO session is valid (8-12 hours from aws sso login)
# - Once SSO session expires, you must run 'aws sso login' again
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
# How AWS SSO Authentication Works
#
# AWS SSO authentication involves three distinct expiration windows that must be understood
# to properly manage credentials. Each layer serves a different purpose and has different
# lifetimes. This script manages the innermost layer (temporary credentials) but depends
# on the outer layers (SSO session and client registration) remaining valid.
#
# Layer 1: Client Registration (90 days typical) - OIDC "Trusted Device" Registration
#    Duration: 90 days for AWS SSO (12 hours for granted, varies by system)
#    Admin-configured: Yes - configurable OAuth 2.0 OIDC client registration period
#    Location: ~/.aws/sso/cache/*.json (separate file with clientId/clientSecret)
#    Created by: aws sso login
#    Key fields:
#       - registrationExpiresAt: Date when client registration expires
#       - clientId: OAuth client identifier
#       - clientSecret: OAuth client secret
#    Purpose: Marks AWS CLI as a trusted OAuth 2.0 client for 90 days
#    Behavior: This is NOT your login session - it's the device trust window
#    Impact if expires: All cached tokens become invalid, must run 'aws sso login'
#    Note: The 90 days does NOT mean your credentials last 90 days
#
# Layer 2: SSO Session (8-12 hours typical) - YOUR ACTUAL LOGIN SESSION
#    Duration: 8-12 hours (commonly 8 hours, configured by AWS administrator)
#    Admin-configured: Yes - set via IAM Identity Center session duration policy
#    Location: ~/.aws/sso/cache/*.json (same file as client registration)
#    Created by: aws sso login
#    Key fields:
#       - refreshToken: Valid for SSO session duration (NOT 90 days!)
#       - accessToken: Short-lived (~1 hour), auto-renewed by refreshToken
#       - expiresAt: When current accessToken expires (~1 hour from now)
#    Purpose: Proves you are authenticated and authorized to request temporary credentials
#    Behavior:
#       - When accessToken expires (~1 hour), AWS CLI auto-renews it using refreshToken
#       - When refreshToken expires (SSO session timeout), renewal fails
#       - refreshToken lifetime is tied to SSO session, NOT client registration
#    Impact if expires: Script fails with "Token has expired and refresh failed"
#    Must do: Run 'aws sso login' to start new SSO session
#    CRITICAL: This script cannot extend your SSO session - only AWS admins can change duration
#
# Layer 3: Temporary IAM Credentials (12 hours typical) - WHAT THIS SCRIPT MANAGES
#    Duration: 12 hours (configured by AWS administrator for permission set)
#    Admin-configured: Yes - set via IAM Identity Center permission set configuration
#    Location: ~/.aws/cli/cache/*.json
#    Created by: aws configure export-credentials (called by this script)
#    Contains:
#       - AccessKeyId: Temporary AWS access key
#       - SecretAccessKey: Temporary AWS secret key
#       - SessionToken: Session token for temporary credentials
#       - Expiration: When these credentials expire
#       - AccountId: AWS account number
#    Purpose: Short-lived AWS API credentials for making AWS service calls
#    Behavior:
#       - Script clears cache and requests fresh credentials every hour
#       - AWS mints new 12-hour credentials using valid SSO session
#       - These are the credentials actually used by AWS CLI/SDK commands
#    Impact if expires: AWS API calls fail until script mints new credentials
#    Note: This script mints fresh 12-hour credentials hourly while SSO session is valid
#
# Layer 4: Custom Export File (This script's output)
#    Location: ~/assets/aws/aws-token.json (configurable)
#    Purpose: Makes temporary IAM credentials available to applications via credential_process
#    Format: JSON with AccessKeyId, SecretAccessKey, SessionToken, Expiration fields
#    Updated: Every time this script successfully runs
#
# Example Timeline (8-hour SSO session):
#    11:00 AM: Run 'aws sso login'
#              → Client registration valid until January 22, 2026 (90 days)
#              → SSO session valid until 7:00 PM today (8 hours)
#              → Initial temporary credentials valid until 11:00 PM (12 hours)
#
#    12:00 PM - 7:00 PM: This script runs hourly
#              → Uses refreshToken to get fresh accessToken (if needed)
#              → Uses accessToken to mint new 12-hour temporary credentials
#              → Exports credentials to custom file
#              → Success - SSO session still valid
#
#    8:00 PM: This script runs
#              → Attempts to use refreshToken
#              → AWS rejects: "Token has expired and refresh failed"
#              → Failure - SSO session expired at 7:00 PM
#              → Must run 'aws sso login' again to start new 8-hour session
#
# Common Misconceptions:
#    - "90 days means my credentials last 90 days" → NO, that's just client registration
#    - "refreshToken automatically renews itself" → NO, it expires with SSO session
#    - "This script extends my SSO session" → NO, only AWS admin can change session duration
#    - "I can work around session timeout" → NO, must re-authenticate after session expires
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

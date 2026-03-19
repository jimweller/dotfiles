#!/bin/bash

# AWS SSO Session and Credential Refresh Script
#
# Self-healing mechanism to maintain near-continuous AWS credentials for up to
# 90 days, leveraging the trusted device registration of AWS SSO.
#
# How this script works:
# 1. Refreshes the SSO session via 'aws sso login'. If the 8-hour session is
#    expired, the 90-day device registration allows non-interactive renewal.
# 2. Mints fresh 12-hour temporary IAM credentials via 'aws configure export-credentials'.
# 3. Writes credentials to an export file for consumption via credential_process.
#
# The 12-hour temporary token remains valid even during the brief window when
# the 8-hour SSO session is expired, ensuring credential_process can always
# serve valid credentials. The next scheduled run re-establishes the SSO session.
#
# Scheduling (launchd on macOS, cron on Linux):
#   00:00, 09:00, 18:00 recommended. Use StartCalendarInterval on macOS for
#   reliability (runs missed jobs on wake).
#
# AWS SSO Authentication Layers
#
# Layer 1: Device Registration (90 days) - OIDC Trusted Client
#   Admin-controlled OAuth 2.0 OIDC client registration period.
#   Location: ~/.aws/sso/cache/*.json (clientId/clientSecret fields)
#   Created by: aws sso login
#   Marks the AWS CLI as a trusted OAuth 2.0 client.
#   This is the device trust window, not the login session.
#   If expired: all cached tokens become invalid, must run 'aws sso login'
#   interactively and complete the browser authentication flow.
#
# Layer 2: SSO Session (8 hours) - Refresh Token
#   Admin-controlled via IAM Identity Center session duration policy.
#   Location: ~/.aws/sso/cache/*.json (refreshToken field)
#   Created by: aws sso login
#   Used to automatically renew the Layer 3 access token.
#   If expired: 'aws sso login' creates a new session non-interactively
#   using the Layer 1 device registration.
#
# Layer 3: SSO Access Token (~1 hour) - Bearer Token
#   Auto-renewed by the Layer 2 refresh token.
#   Location: ~/.aws/sso/cache/*.json (accessToken/expiresAt fields)
#   Used to call sso:GetRoleCredentials to obtain Layer 4 IAM credentials.
#   If expired: AWS CLI silently renews it using the refresh token.
#   If the refresh token is also expired: renewal fails, 'aws sso login' required.
#
# Layer 4: Temporary IAM Credentials (12 hours) - STS Credentials
#   Admin-controlled via IAM Identity Center permission set configuration.
#   Location: ~/.aws/cli/cache/*.json
#   Created by: 'aws configure export-credentials', which internally calls
#   sso:GetRoleCredentials using the Layer 3 access token to mint STS credentials.
#   Contains AccessKeyId, SecretAccessKey, SessionToken, Expiration.
#   These are the credentials used by AWS CLI/SDK for actual AWS API calls.
#   If expired: AWS API calls fail until new credentials are minted.
#
# Layer 5: Export File (refresh schedule) - Script Output
#   Not part of standard AWS SSO. Customization provided by this script.
#   Duration: refreshed by job schedule every 9 hours (00:00, 09:00, 18:00)
#   Location: ~/assets/aws/aws-token.json (configurable)
#   Makes Layer 4 credentials available to applications via credential_process.
#   Decouples credential consumers from the credential source.
#
# Example Timeline (8-hour SSO session, 12am/9am/6pm schedule):
#
#   6pm  - Layer 2 expired. 'aws sso login' creates new refresh token (8h, until 2am).
#          'export-credentials' mints new IAM credentials (12h, until 6am).
#   12am - Layer 2 still valid (expires 2am). New IAM credentials (12h, until 12pm).
#   2am  - Layer 2 expires. Layer 4 from 12am still valid (until 12pm).
#          credential_process continues serving Layer 5 export file.
#   9am  - Layer 2 expired. New refresh token (8h, until 5pm).
#          New IAM credentials (12h, until 9pm).
#   6pm  - Cycle repeats.
#

# configuration - must use full paths for launchd
AWS_CMD="/opt/homebrew/bin/aws"
JQ_CMD="/opt/homebrew/bin/jq"
DATE_CMD="/opt/homebrew/bin/gdate"

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
  local content=$($JQ_CMD -c '
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

log "[INFO] AWS Token Refresh Started"

# Step 1: Refresh the SSO session. If the session is expired, this will create a
# new 8-hour session non-interactively. If valid, it does nothing.
log "[INFO] Attempting to refresh SSO session..."
if $AWS_CMD sso login --profile "$AWS_PROFILE_NAME" >> "$LOG_FILE" 2>&1; then
  log "[INFO] SSO session is valid or was successfully renewed."
else
  log "[ERROR] Failed to refresh SSO session. Manual login may be required."
  exit 1
fi

# Step 2: Clear CLI cache to ensure we get a new temporary token.
if [ -d "$CLI_CACHE_DIR" ] && ls "$CLI_CACHE_DIR"/*.json > /dev/null 2>&1; then
  log "[INFO] Clearing AWS CLI cache"
  rm -f "$CLI_CACHE_DIR"/*.json > /dev/null 2>&1
fi

# Step 3: Get fresh temporary token from AWS using the now-valid SSO session.
log "[INFO] Requesting new temporary credentials..."
$AWS_CMD configure export-credentials --profile "$AWS_PROFILE_NAME" --output json > "$CREDS_FILE" 2>> "$LOG_FILE"

if [ $? -ne 0 ]; then
  log "[ERROR] Failed to get temporary token even after SSO refresh."
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

log "[SUCCESS] Refreshed. Expiration: $EXPIRATION (${time_remaining} remaining)"

# inspect cache files after refresh to see what changed
log "[INFO] Post-refresh cache state:"
SSO_CACHE_DIR="$HOME/.aws/sso/cache"
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
else
  log "[INFO] No CLI cache files found after refresh"
fi

log "[INFO] AWS Token Refresh Complete"

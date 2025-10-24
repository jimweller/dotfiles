#!/bin/bash

# AWS Temporary Credential Refresh Script
#
# Uses a long-lived AWS SSO session token to periodically refresh a short-lived
# temporary token, ensuring it's always available for applications. It is intended
# to be run as a scheduled job or in an infinite loop. The scheduled job interval
# should be less than the temporary token lifetime (8h < 12h at my work).
#
# This script clears the CLI cache before calling export-credentials to force a fresh
# temporary token every time. That way there is no need to calculate the difference
# between the job interval and expiration duration.
#
# How AWS token caching works
#
# SSO Session Tokens (Long-lived, duration configured by AWS admins)
#    Location: ~/.aws/sso/cache/*.json
#    Created by: aws sso login
#    Contains: OAuth access/refresh tokens that prove your identity
#    Used by: AWS CLI and SDKs to request/refresh a temporary access token
#
# Temporary Access Token (Short-lived, duration configured by AWS admins)
#    Location: ~/.aws/cli/cache/*.json
#    Created by: Any AWS CLI commands that make api calls (e.g., aws configure export-credentials OR aws sts get-caller-identity)
#    Contains: AccessKeyId, SecretAccessKey, SessionToken
#    Used by: AWS CLI and SDKs for API calls
#
# Custom Export File (This script's output)
#    Location: ~/assets/aws/aws-token.json (configurable)
#    Purpose: Makes temporary token available to a custom credential_process in aws profile config. Like the host exporting credentials to a container
#
# How 'aws configure export-credentials' works:
# - Checks CLI cache for valid temporary token
# - If expired/missing: Makes STS AssumeRole call using SSO token to get a fresh temporary token
# - Updates CLI cache with result
#
# Scheduling with launchd on MacOS:
#  Put plist file in: ~/Library/LaunchAgents/com.user.refreshawstoken.plist
#  The plist filename must match the key: <string>com.user.refreshawstoken</string>
#  Load: launchctl load ~/Library/LaunchAgents/com.user.refreshawstoken.plist
#  Unload: launchctl unload ~/Library/LaunchAgents/com.user.refreshawstoken.plist
#  (if you change the plist file you must unload/load to refresh the job)

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

mkdir -p "$CREDS_DIR"

log "Refreshing AWS temporary token..."

# clear CLI cache to force fresh temporary token
if [ -d "$CLI_CACHE_DIR" ] && ls "$CLI_CACHE_DIR"/*.json > /dev/null 2>&1; then
  log "Clearing AWS CLI cache to force new temporary token"
  rm -f "$CLI_CACHE_DIR"/*.json > /dev/null 2>&1
fi

# get fresh temporary token from AWS (uses SSO token to make STS call)
$AWS_CMD configure export-credentials --profile "$AWS_PROFILE_NAME" --output json > "$CREDS_FILE" 2>> "$LOG_FILE"

if [ $? -ne 0 ]; then
  log "ERROR: Failed to get temporary token. Check SSO login status (aws sso login --profile $AWS_PROFILE_NAME)"
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
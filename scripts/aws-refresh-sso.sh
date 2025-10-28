#!/bin/bash

# AWS SSO Session Refresh Script
#
# Runs 'aws sso login' every 6 hours to maintain SSO session for 90 days.
# After the initial login (which requires browser interaction), subsequent logins
# auto-complete in the browser tab with no user interaction needed.
#
# This script maintains the 8-hour SSO session by refreshing every 6 hours,
# ensuring the refreshToken never expires during the 90-day client registration window.
#
# Scheduling with launchd on MacOS:
#  Put plist file in: ~/Library/LaunchAgents/com.user.awsrefreshsso.plist
#  Load: launchctl load ~/Library/LaunchAgents/com.user.awsrefreshsso.plist
#  Unload: launchctl unload ~/Library/LaunchAgents/com.user.awsrefreshsso.plist
#  (if you change the plist file you must unload/load to refresh the job)
#
# see also:
#  - aws-refresh-sso.plist - for scheduled job
#  - aws-refresh-token.sh - for refreshing temporary access token
#
# Configuration - must use full paths for launchd
ASDF_CMD="/opt/homebrew/bin/asdf"
AWS_CMD="$($ASDF_CMD which aws)"
DATE_CMD="/opt/homebrew/bin/gdate"

AWS_PROFILE_NAME="mcg"
CREDS_DIR="$HOME/assets/aws"
LOG_FILE="$CREDS_DIR/refresh.log"

log() {
  echo "$($DATE_CMD +'%Y-%m-%d %T %Z'): $1" >> "$LOG_FILE"
}

mkdir -p "$CREDS_DIR"

log "==== AWS SSO Session Refresh Started ===="

# Run aws sso login (browser will open and auto-complete)
if $AWS_CMD sso login --profile "$AWS_PROFILE_NAME" >> "$LOG_FILE" 2>&1; then
  log "Successfully refreshed SSO session"
  log "==== AWS SSO Session Refresh Complete ===="
  exit 0
else
  log "ERROR: Failed to refresh SSO session"
  log "ACTION REQUIRED: Check browser and manually authenticate"
  log "==== AWS SSO Session Refresh Failed ===="
  exit 1
fi
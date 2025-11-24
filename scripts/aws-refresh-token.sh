#!/bin/bash

# AWS SSO Session and Credential Refresh Script
#
# This script provides a self-healing mechanism to maintain a nearly continuous AWS session
# for up to 90 days, leveraging the trusted device registration of AWS SSO.
#
# How this script works:
# 1. Refreshes the SSO Session: It runs 'aws sso login'. If the 8-hour SSO session
#    is expired, this command uses the 90-day trusted device registration to
#    non-interactively start a new 8-hour session. If the session is still valid,
#    it does nothing.
# 2. Mints Fresh Temporary Credentials: It then runs 'aws configure export-credentials'
#    to generate a new set of 12-hour temporary IAM credentials.
# 3. Exports for Applications: The new credentials are saved to a custom file, making
#    them available to other applications via the 'credential_process' in ~/.aws/config.
#
# This creates a resilient cycle: the 12-hour temporary token remains valid even
# during the brief window when the 8-hour SSO session is expired, ensuring that
# the 'credential_process' helper can always serve valid credentials. The next
# scheduled run then automatically re-establishes the SSO session.
#
# Scheduling with launchd on MacOS:
#  - Use StartCalendarInterval for reliability, as it runs missed jobs on wake.
#  - A schedule of 00:00, 09:00, and 18:00 is recommended. This ensures the 8-hour
#    SSO session is renewed shortly after it expires, providing continuous coverage.
#
# How AWS SSO Authentication Works
#
# AWS SSO authentication involves three distinct expiration windows that must be understood
# to properly manage credentials. This script leverages all three layers to provide a
# long-running, automated session.
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
#    Impact if expires: The next step in this script ('aws sso login') will automatically
#                       create a new session.
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
#       - This script requests fresh credentials on a fixed schedule (e.g., every 9 hours).
#       - AWS mints new 12-hour credentials using the just-refreshed SSO session.
#       - These are the credentials actually used by AWS CLI/SDK commands.
#    Impact if expires: The 'credential_process' continues to serve the previous, still-valid
#                       token until the next scheduled run mints a new one.
#
# Layer 4: Custom Export File (This script's output)
#    Location: ~/assets/aws/aws-token.json (configurable)
#    Purpose: Makes temporary IAM credentials available to applications via credential_process
#    Format: JSON with AccessKeyId, SecretAccessKey, SessionToken, Expiration fields
#    Updated: Every time this script successfully runs
#
# Example Timeline (8-hour SSO session with 00:00, 09:00, 18:00 schedule):
#    18:00: Script runs. SSO session is expired.
#           → 'aws sso login' creates a NEW 8-hour session (valid until 02:00).
#           → 'export-credentials' creates a NEW 12-hour token (valid until 06:00).
#
#    00:00: Script runs. SSO session is still valid (expires at 02:00).
#           → 'aws sso login' does nothing, session still expires at 02:00.
#           → 'export-credentials' creates a NEW 12-hour token (valid until 12:00).
#
#    02:00: The 8-hour SSO session expires.
#           → From 02:00 to 09:00, any new process uses the still-valid temporary
#             token from 00:00 via the 'credential_process' helper.
#
#    09:00: Script runs. SSO session is expired.
#           → 'aws sso login' creates a NEW 8-hour session (valid until 17:00).
#           → 'export-credentials' creates a NEW 12-hour token (valid until 21:00).
#
# This cycle continues, providing uninterrupted credential availability.
#

# configuration - must use full paths for launchd
ASDF_CMD="/opt/homebrew/bin/asdf"
AWS_CMD="$($ASDF_CMD which aws)"
JQ_CMD="$($ASDF_CMD which jq)"
DATE_CMD="/opt/homebrew/bin/gdate" # use gnu date for portability (brew install coreutils)

AWS_PROFILE_NAME="mcg"
CREDS_DIR="$HOME/assets/aws"
CREDS_FILE="$CREDS_DIR/aws-token.json"
LOG_FILE="$CREDS_DIR/refresh.log"
CLI_CACHE_DIR="$HOME/.aws/cli/cache"

# kubernetes configuration
KUBECTL_CMD="$($ASDF_CMD which kubectl 2>/dev/null)"
K8S_CONTEXT="colima"
K8S_NAMESPACE="davit"
K8S_SECRET_NAME="aws-credentials"

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

# Step 4: Update Kubernetes secret in colima cluster (davit namespace)
log "[INFO] Updating Kubernetes secret in colima cluster..."

# Preflight check: Verify kubectl is available
if [ -z "$KUBECTL_CMD" ] || [ ! -x "$KUBECTL_CMD" ]; then
  log "[WARN] kubectl not found, skipping Kubernetes secret update"
  exit 0
fi

# Preflight check: Verify colima cluster is accessible
if ! $KUBECTL_CMD cluster-info --context="$K8S_CONTEXT" > /dev/null 2>&1; then
  log "[WARN] Kubernetes context '$K8S_CONTEXT' is not accessible, skipping secret update"
  exit 0
fi

# Preflight check: Verify davit namespace exists
if ! $KUBECTL_CMD get namespace "$K8S_NAMESPACE" --context="$K8S_CONTEXT" > /dev/null 2>&1; then
  log "[WARN] Kubernetes namespace '$K8S_NAMESPACE' does not exist, skipping secret update"
  exit 0
fi

# Update the secret (idempotent: creates if missing, updates if exists)
if $KUBECTL_CMD create secret generic "$K8S_SECRET_NAME" \
  --from-file=aws-token.json="$CREDS_FILE" \
  --namespace="$K8S_NAMESPACE" \
  --context="$K8S_CONTEXT" \
  --dry-run=client -o yaml 2>> "$LOG_FILE" | \
  $KUBECTL_CMD apply --context="$K8S_CONTEXT" -f - >> "$LOG_FILE" 2>&1; then
  log "[SUCCESS] Kubernetes secret '$K8S_SECRET_NAME' updated in $K8S_CONTEXT/$K8S_NAMESPACE"
else
  log "[ERROR] Failed to update Kubernetes secret (non-fatal, AWS credentials still refreshed)"
fi

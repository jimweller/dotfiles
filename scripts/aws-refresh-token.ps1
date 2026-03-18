#Requires -Version 5.1

# AWS SSO Session and Credential Refresh Script (Windows)
#
# Windows port of aws-refresh-token.sh. See that file for full documentation
# of the 4-layer token lifecycle.
#
# This script provides a self-healing mechanism to maintain a nearly continuous AWS session
# for up to 90 days, leveraging the trusted device registration of AWS SSO.
#
# How this script works:
# 1. Refreshes the SSO Session: Runs 'aws sso login'. If the 8-hour SSO session
#    is expired, this command uses the 90-day trusted device registration to
#    start a new 8-hour session via browser-based IdC flow.
# 2. Mints Fresh Temporary Credentials: Runs 'aws configure export-credentials'
#    to generate a new set of 12-hour temporary IAM credentials.
# 3. Exports for Applications: The new credentials are saved to a custom file, making
#    them available to other applications via 'credential_process' in ~/.aws/config.
#
# Scheduling with Task Scheduler:
#  - Use aws-refresh-token-install-task.ps1 to register the scheduled task.
#  - Task runs at 00:00, 09:00, and 18:00 in an interactive session so the
#    browser can open for the IdC authorization flow.

$ErrorActionPreference = "Stop"

$AwsProfileName = "mcg"
$CredsDir = Join-Path $env:USERPROFILE "assets\aws"
$CredsFile = Join-Path $CredsDir "aws-token.json"
$LogFile = Join-Path $CredsDir "refresh.log"
$CliCacheDir = Join-Path $env:USERPROFILE ".aws\cli\cache"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss K"
    "${timestamp}: $Message" | Out-File -Append -FilePath $LogFile -Encoding utf8
}

function Write-LogJsonMetadata {
    param(
        [string]$File,
        [string]$Label
    )

    if (-not (Test-Path $File)) {
        Write-Log "$Label`: File not found"
        return
    }

    Write-Log "$Label`: $(Split-Path $File -Leaf)"

    try {
        $obj = Get-Content $File -Raw | ConvertFrom-Json
        $sensitiveFields = @("accessToken", "refreshToken", "clientSecret", "AccessKeyId", "SecretAccessKey", "SessionToken")
        foreach ($field in $sensitiveFields) {
            if ($obj.PSObject.Properties[$field]) {
                $obj.$field = "*****"
            }
        }
        $masked = $obj | ConvertTo-Json -Compress
        Write-Log $masked
    }
    catch {
        Write-Log "  ERROR: Failed to parse JSON"
    }
}

if (-not (Test-Path $CredsDir)) {
    New-Item -ItemType Directory -Path $CredsDir -Force | Out-Null
}

Write-Log "[INFO] AWS Token Refresh Started"

# Step 1: Refresh the SSO session. Opens browser for IdC flow if needed.
Write-Log "[INFO] Attempting to refresh SSO session..."
$ssoOutput = & aws sso login --profile $AwsProfileName 2>&1
$ssoExitCode = $LASTEXITCODE

$ssoOutput | Out-File -Append -FilePath $LogFile -Encoding utf8

if ($ssoExitCode -ne 0) {
    Write-Log "[ERROR] Failed to refresh SSO session. Manual login may be required."
    exit 1
}

Write-Log "[INFO] SSO session is valid or was successfully renewed."

# Step 2: Clear CLI cache to ensure we get a new temporary token.
if ((Test-Path $CliCacheDir) -and (Get-ChildItem "$CliCacheDir\*.json" -ErrorAction SilentlyContinue)) {
    Write-Log "[INFO] Clearing AWS CLI cache"
    Remove-Item "$CliCacheDir\*.json" -Force -ErrorAction SilentlyContinue
}

# Step 3: Get fresh temporary token from AWS using the now-valid SSO session.
Write-Log "[INFO] Requesting new temporary credentials..."
$credsOutput = & aws configure export-credentials --profile $AwsProfileName --output json 2>&1
$credsExitCode = $LASTEXITCODE

if ($credsExitCode -ne 0) {
    $credsOutput | Out-File -Append -FilePath $LogFile -Encoding utf8
    Write-Log "[ERROR] Failed to get temporary token even after SSO refresh."
    exit 1
}

$credsOutput | Out-File -FilePath $CredsFile -Encoding utf8

# Calculate and log expiration details.
try {
    $creds = $credsOutput | ConvertFrom-Json
    $expiration = [DateTimeOffset]::Parse($creds.Expiration)
    $now = [DateTimeOffset]::UtcNow
    $remaining = $expiration - $now
    $timeRemaining = "{0:D2}h {1:D2}m {2:D2}s" -f [int]$remaining.TotalHours, $remaining.Minutes, $remaining.Seconds
    Write-Log "[SUCCESS] Refreshed. Expiration: $($creds.Expiration) (${timeRemaining} remaining)"
}
catch {
    Write-Log "[SUCCESS] Refreshed. Could not parse expiration."
}

# Inspect cache files after refresh.
Write-Log "[INFO] Post-refresh cache state:"
$ssoCacheDir = Join-Path $env:USERPROFILE ".aws\sso\cache"
if (Test-Path $ssoCacheDir) {
    Get-ChildItem "$ssoCacheDir\*.json" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-LogJsonMetadata -File $_.FullName -Label "SSO Cache"
    }
}

if ((Test-Path $CliCacheDir) -and (Get-ChildItem "$CliCacheDir\*.json" -ErrorAction SilentlyContinue)) {
    Get-ChildItem "$CliCacheDir\*.json" | ForEach-Object {
        Write-LogJsonMetadata -File $_.FullName -Label "CLI Cache"
    }
}
else {
    Write-Log "[INFO] No CLI cache files found after refresh"
}

Write-Log "[INFO] AWS Token Refresh Complete"

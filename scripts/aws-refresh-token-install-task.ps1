#Requires -Version 5.1

# Registers the AWSRefreshToken scheduled task from the XML definition.
# Run this from an elevated (Administrator) PowerShell prompt.

$ErrorActionPreference = "Stop"

$TaskName = "AWSRefreshToken"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$XmlPath = Join-Path $ScriptDir "aws-refresh-token-task.xml"

if (-not (Test-Path $XmlPath)) {
    Write-Error "Task XML not found: $XmlPath"
    exit 1
}

$principal = [System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run this script as Administrator."
    exit 1
}

$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Removing existing task '$TaskName'..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

$xml = Get-Content $XmlPath -Raw
$xml = $xml -replace '%USERPROFILE%', $env:USERPROFILE

Register-ScheduledTask -TaskName $TaskName -Xml $xml -User $env:USERNAME

Write-Host "Scheduled task '$TaskName' registered."
Write-Host "  Schedule: daily at 00:00, 09:00, 18:00"
Write-Host "  Session:  interactive (browser can open for IdC flow)"
Write-Host "  Script:   $ScriptDir\aws-refresh-token.ps1"
Write-Host ""
Write-Host "To run immediately: Start-ScheduledTask -TaskName $TaskName"
Write-Host "To verify:          Get-ScheduledTask -TaskName $TaskName | Format-List"
Write-Host "To uninstall:       Unregister-ScheduledTask -TaskName $TaskName"

<#
.SYNOPSIS
    Creates a versioned backup of the ESS Pre-flight Validator

.DESCRIPTION
    Creates a timestamped ZIP backup with current version number.
    Saves to Desktop with format: ESS-PreFlight-Validator-vX.Y.Z-YYYYMMDD-HHMMSS.zip

.PARAMETER Version
    Version number (e.g., "1.1.0"). If not specified, reads from VERSION.txt

.PARAMETER IncludeReports
    Include generated reports in backup (default: false)

.EXAMPLE
    .\Create-Backup.ps1
    Creates backup with current version from VERSION.txt

.EXAMPLE
    .\Create-Backup.ps1 -Version "1.2.0"
    Creates backup with specified version
#>

[CmdletBinding()]
param(
    [string]$Version,
    [switch]$IncludeReports
)

$ErrorActionPreference = "Stop"

# Read version if not specified
if (-not $Version) {
    $versionFile = Join-Path $PSScriptRoot "VERSION.txt"
    if (Test-Path $versionFile) {
        $versionContent = Get-Content $versionFile | Where-Object { $_ -match '^VERSION=' }
        $Version = ($versionContent -split '=')[1]
    } else {
        $Version = "unknown"
    }
}

# Create backup
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupName = "ESS-PreFlight-Validator-v$Version-$timestamp"
$backupPath = Join-Path $HOME "Desktop\$backupName.zip"

Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           ESS PRE-FLIGHT VALIDATOR BACKUP                    ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Version: " -NoNewline; Write-Host "v$Version" -ForegroundColor Yellow
Write-Host "  Time: " -NoNewline; Write-Host $timestamp -ForegroundColor Gray
Write-Host ""

# Items to backup
$items = @(
    "PowerShell\*.ps1",
    "PowerShell\*.psm1",
    "Documentation\*.md",
    "*.md",
    "VERSION.txt",
    ".gitignore"
)

if ($IncludeReports) {
    Write-Host "  Including reports..." -ForegroundColor Yellow
    $items += "ESS-Reports\*"
}

# Collect files
$filesToBackup = @()
foreach ($pattern in $items) {
    $files = Get-ChildItem (Join-Path $PSScriptRoot $pattern) -ErrorAction SilentlyContinue
    $filesToBackup += $files
}

# Create archive
Write-Host "  Archiving $($filesToBackup.Count) files..." -ForegroundColor Cyan
Compress-Archive -Path $filesToBackup.FullName -DestinationPath $backupPath -Force

if (Test-Path $backupPath) {
    $file = Get-Item $backupPath
    Write-Host ""
    Write-Host "  ✓ BACKUP COMPLETE!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Location: " -NoNewline
    Write-Host $file.FullName -ForegroundColor Cyan
    Write-Host "  Size: " -NoNewline
    Write-Host "$([math]::Round($file.Length / 1KB, 1)) KB" -ForegroundColor Cyan
    Write-Host ""
    
    # Log backup
    $logFile = Join-Path $PSScriptRoot "backup-log.txt"
    "$timestamp - v$Version - $($file.Name)" | Add-Content $logFile
    
} else {
    Write-Host "  ✗ Backup failed!" -ForegroundColor Red
    exit 1
}

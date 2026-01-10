<#
.SYNOPSIS
    Updates version number across all ESS Pre-flight Validator files

.DESCRIPTION
    Updates VERSION.txt, commits changes to Git, and optionally creates a backup.

.PARAMETER NewVersion
    New version number in format X.Y.Z (e.g., "1.2.0")

.PARAMETER Message
    Commit message describing the changes

.PARAMETER CreateBackup
    Create a backup before updating version (default: true)

.EXAMPLE
    .\Update-Version.ps1 -NewVersion "1.2.0" -Message "Added new validation checkpoints"

.EXAMPLE
    .\Update-Version.ps1 -NewVersion "1.1.1" -Message "Bug fixes" -CreateBackup:$false
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$NewVersion,
    
    [Parameter(Mandatory=$true)]
    [string]$Message,
    
    [switch]$CreateBackup = $true
)

$ErrorActionPreference = "Stop"

Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           ESS PRE-FLIGHT VALIDATOR VERSION UPDATE           ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Read current version
$versionFile = Join-Path $PSScriptRoot "VERSION.txt"
$currentVersion = "unknown"
if (Test-Path $versionFile) {
    $versionContent = Get-Content $versionFile | Where-Object { $_ -match '^VERSION=' }
    $currentVersion = ($versionContent -split '=')[1]
}

Write-Host "  Current Version: " -NoNewline
Write-Host "v$currentVersion" -ForegroundColor Yellow
Write-Host "  New Version: " -NoNewline
Write-Host "v$NewVersion" -ForegroundColor Green
Write-Host ""

# Confirm
$confirm = Read-Host "  Proceed with version update? (Y/N)"
if ($confirm -ne 'Y') {
    Write-Host "  Cancelled." -ForegroundColor Yellow
    exit 0
}

# Create backup
if ($CreateBackup) {
    Write-Host "`n  Creating backup..." -ForegroundColor Cyan
    & (Join-Path $PSScriptRoot "Create-Backup.ps1") -Version $currentVersion
}

# Update VERSION.txt
Write-Host "`n  Updating VERSION.txt..." -ForegroundColor Cyan
$versionContent = Get-Content $versionFile
$versionContent = $versionContent -replace '^VERSION=.*', "VERSION=$NewVersion"
$versionContent = $versionContent -replace '^RELEASE_DATE=.*', "RELEASE_DATE=$(Get-Date -Format 'yyyy-MM-dd')"
$versionContent = $versionContent -replace '^BUILD=.*', "BUILD=$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$versionContent = $versionContent -replace '^FULL_VERSION=.*', "FULL_VERSION=$NewVersion-stable"
$versionContent | Set-Content $versionFile

# Update CHANGELOG.md
Write-Host "  Don't forget to update CHANGELOG.md manually!" -ForegroundColor Yellow
Write-Host "  Add entry for version $NewVersion with your changes." -ForegroundColor Yellow

# Git operations
Write-Host "`n  Git operations..." -ForegroundColor Cyan
Push-Location $PSScriptRoot

try {
    # Check if git repo
    $gitExists = Test-Path ".git"
    
    if ($gitExists) {
        # Stage changes
        git add .
        
        # Commit
        git commit -m "v$NewVersion - $Message"
        
        # Create tag
        git tag -a "v$NewVersion" -m "Release v$NewVersion"
        
        Write-Host "  ✓ Git commit and tag created" -ForegroundColor Green
        Write-Host ""
        Write-Host "  To push to remote:" -ForegroundColor Yellow
        Write-Host "    git push origin main" -ForegroundColor Gray
        Write-Host "    git push origin v$NewVersion" -ForegroundColor Gray
    } else {
        Write-Host "  ⚠ Not a git repository - skipping git operations" -ForegroundColor Yellow
    }
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "  ✓ VERSION UPDATE COMPLETE!" -ForegroundColor Green
Write-Host "  New version: v$NewVersion" -ForegroundColor Cyan
Write-Host ""

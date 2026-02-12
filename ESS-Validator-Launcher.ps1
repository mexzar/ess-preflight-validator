<#
.SYNOPSIS
    ESS Pre-Flight Validator - Launcher
    
.DESCRIPTION
    Thin launcher that spawns PowerShell 7 with session mode.
    Modules load once, then you can run multiple tests instantly.
    Designed for compilation to .exe via PS2EXE with -NoConsole.
    
.NOTES
    Version: 1.7.0
    Author: ESS Deployment Team
#>

#Requires -Version 5.1

$ErrorActionPreference = "Continue"

# Get script location - works for both .ps1 and .exe (PS2EXE)
if ($MyInvocation.MyCommand.Path) {
    $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
} elseif ($PSScriptRoot) {
    $ScriptRoot = $PSScriptRoot
} else {
    # Fallback for PS2EXE compiled exe
    $ScriptRoot = [System.IO.Path]::GetDirectoryName([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
}

# Check for PowerShell 7
$pwsh = Get-Command pwsh -ErrorAction SilentlyContinue

if (-not $pwsh) {
    # Show error in a message box since we're running without console
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        "PowerShell 7 is required but not installed.`n`nTo install:`n  winget install Microsoft.PowerShell`n`nOr download from:`n  https://github.com/PowerShell/PowerShell/releases",
        "ESS Pre-Flight Validator",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
    exit 1
}

# Check for session script
$sessionScript = Join-Path $ScriptRoot "ESS-Validator-Session.ps1"

if (-not (Test-Path $sessionScript)) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        "ESS-Validator-Session.ps1 not found.`n`nExpected at:`n$sessionScript",
        "ESS Pre-Flight Validator",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
    exit 1
}

# Launch PowerShell 7 with the session script
# -ExecutionPolicy Bypass is required for downloaded/unsigned scripts
Start-Process pwsh -ArgumentList "-ExecutionPolicy", "Bypass", "-NoExit", "-File", $sessionScript, "-ScriptRoot", $ScriptRoot

exit 0

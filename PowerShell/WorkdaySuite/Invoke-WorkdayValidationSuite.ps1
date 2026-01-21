<#
.SYNOPSIS
    Comprehensive Workday integration validation suite for ESS deployment

.DESCRIPTION
    Runs all Workday-specific validations including:
    - Environment variables configuration (RaaS account, report name, instance)
    - Workday API connectivity
    - SSO/OAuth configuration
    - Connection references status
    - Power Automate flow status

.PARAMETER EnvironmentId
    Power Platform environment ID containing the Workday solution

.PARAMETER SkipConnectivityTest
    Skip the interactive connectivity test (useful for automated runs)

.PARAMETER Credential
    PSCredential for Workday ISU account. If not provided, will prompt interactively.

.EXAMPLE
    Invoke-WorkdayValidationSuite -EnvironmentId "c3446975-d597-e5b4-8724-d5be9e5c4303"

.EXAMPLE
    Invoke-WorkdayValidationSuite -EnvironmentId "c3446975-..." -SkipConnectivityTest

.NOTES
    Version: 1.2.0
    Part of ESS Pre-flight Validator
    Documentation: https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/workday
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$EnvironmentId,

    [Parameter()]
    [switch]$SkipConnectivityTest,

    [Parameter()]
    [System.Management.Automation.PSCredential]$Credential
)

$ErrorActionPreference = "Stop"

# Import helper functions from parent module if not already loaded
$modulePath = Join-Path $PSScriptRoot "..\ESS-Validator.psm1"
if (-not (Get-Command Add-ValidationResult -ErrorAction SilentlyContinue)) {
    Import-Module $modulePath -Force
}

# Dot-source other Workday suite scripts
. (Join-Path $PSScriptRoot "Test-WorkdayEnvironmentVariables.ps1")
. (Join-Path $PSScriptRoot "Test-WorkdayConnectionReferences.ps1")
. (Join-Path $PSScriptRoot "Test-WorkdayFlowStatus.ps1")

function Invoke-WorkdayValidationSuite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvironmentId,

        [Parameter()]
        [switch]$SkipConnectivityTest,

        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential
    )

    Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║           WORKDAY INTEGRATION VALIDATION SUITE               ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  Environment: $EnvironmentId" -ForegroundColor Cyan
    Write-Host ""

    $suiteResults = @()
    $suiteStartTime = Get-Date

    # ═══════════════════════════════════════════════════════════════════
    # Step 1: Environment Variables Validation
    # ═══════════════════════════════════════════════════════════════════
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "  📋 Step 1/4: Environment Variables" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    $envVarResults = Test-WorkdayEnvironmentVariables -EnvironmentId $EnvironmentId
    $suiteResults += $envVarResults

    # ═══════════════════════════════════════════════════════════════════
    # Step 2: Connection References Validation
    # ═══════════════════════════════════════════════════════════════════
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "  🔗 Step 2/4: Connection References" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    $connRefResults = Test-WorkdayConnectionReferences -EnvironmentId $EnvironmentId
    $suiteResults += $connRefResults

    # ═══════════════════════════════════════════════════════════════════
    # Step 3: Flow Status Validation
    # ═══════════════════════════════════════════════════════════════════
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "  ⚡ Step 3/4: Flow Status" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    $flowResults = Test-WorkdayFlowStatus -EnvironmentId $EnvironmentId
    $suiteResults += $flowResults

    # ═══════════════════════════════════════════════════════════════════
    # Step 4: Connectivity Test (Optional)
    # ═══════════════════════════════════════════════════════════════════
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "  🌐 Step 4/4: Workday Connectivity" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

    if ($SkipConnectivityTest) {
        Write-Host "  ⏭️  Connectivity test skipped (use -SkipConnectivityTest:$false to enable)" -ForegroundColor Yellow
        $suiteResults += [PSCustomObject]@{
            CheckpointId = 'WD-CONN-001'
            Category     = 'Workday'
            Priority     = 'High'
            Status       = 'NotConfigured'
            Result       = 'Connectivity test skipped'
            Remediation  = 'Run Test-WorkdayConnectivity manually or remove -SkipConnectivityTest flag'
        }
    } else {
        Write-Host ""
        $runConnTest = Read-Host "  Run Workday API connectivity test? (Y/N)"
        
        if ($runConnTest -eq 'Y') {
            $connectivityScript = Join-Path $PSScriptRoot "Test-WorkdayConnectivity.ps1"
            if (Test-Path $connectivityScript) {
                if ($Credential) {
                    & $connectivityScript -Credential $Credential
                } else {
                    & $connectivityScript
                }
            } else {
                Write-Host "  ⚠️  Test-WorkdayConnectivity.ps1 not found in WorkdaySuite folder" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  ⏭️  Connectivity test skipped by user" -ForegroundColor Yellow
        }
    }

    # ═══════════════════════════════════════════════════════════════════
    # Summary
    # ═══════════════════════════════════════════════════════════════════
    $duration = (Get-Date) - $suiteStartTime
    
    $passed = ($suiteResults | Where-Object Status -eq 'Passed').Count
    $failed = ($suiteResults | Where-Object Status -eq 'Failed').Count
    $warnings = ($suiteResults | Where-Object Status -eq 'Warning').Count
    $notConfigured = ($suiteResults | Where-Object Status -eq 'NotConfigured').Count

    Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║           WORKDAY VALIDATION SUMMARY                         ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  Total Checks: $($suiteResults.Count)"
    Write-Host "  ✅ Passed: $passed" -ForegroundColor Green
    Write-Host "  ❌ Failed: $failed" -ForegroundColor Red
    Write-Host "  ⚠️  Warnings: $warnings" -ForegroundColor Yellow
    Write-Host "  ℹ️  Not Configured: $notConfigured" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Duration: $($duration.TotalSeconds.ToString('F1')) seconds" -ForegroundColor DarkGray
    Write-Host ""

    if ($failed -eq 0 -and $warnings -eq 0) {
        Write-Host "  ✅ WORKDAY INTEGRATION READY" -ForegroundColor Green
    } elseif ($failed -eq 0) {
        Write-Host "  ⚠️  WORKDAY READY WITH WARNINGS" -ForegroundColor Yellow
    } else {
        Write-Host "  ❌ WORKDAY ISSUES FOUND - Review failed checks above" -ForegroundColor Red
    }
    Write-Host ""

    return $suiteResults
}

# Run if called directly
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-WorkdayValidationSuite -EnvironmentId $EnvironmentId -SkipConnectivityTest:$SkipConnectivityTest -Credential $Credential
}

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
    - SSO security domain diagnostics (optional)

.PARAMETER EnvironmentId
    Power Platform environment ID containing the Workday solution

.PARAMETER SkipConnectivityTest
    Skip the interactive connectivity test (useful for automated runs)

.PARAMETER IncludeSSODiagnostics
    Include deep SSO configuration analysis with security domain checklist

.PARAMETER GenerateChecklist
    Export Workday Admin checklist for security domain permissions

.PARAMETER Credential
    PSCredential for Workday ISU account. If not provided, will prompt interactively.

.EXAMPLE
    Invoke-WorkdayValidationSuite -EnvironmentId "00000000-0000-0000-0000-000000000000"

.EXAMPLE
    Invoke-WorkdayValidationSuite -EnvironmentId "your-environment-id" -IncludeSSODiagnostics

.EXAMPLE
    Invoke-WorkdayValidationSuite -EnvironmentId "your-environment-id" -IncludeSSODiagnostics -GenerateChecklist

.NOTES
    Version: 1.3.0
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
    [switch]$IncludeSSODiagnostics,

    [Parameter()]
    [switch]$GenerateChecklist,

    [Parameter()]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter()]
    [string]$ExportPath
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
. (Join-Path $PSScriptRoot "Test-WorkdaySSOConfiguration.ps1")

function Invoke-WorkdayValidationSuite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvironmentId,

        [Parameter()]
        [switch]$SkipConnectivityTest,

        [Parameter()]
        [switch]$IncludeSSODiagnostics,

        [Parameter()]
        [switch]$GenerateChecklist,

        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential
    )

    Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║           WORKDAY INTEGRATION VALIDATION SUITE               ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  Environment: $EnvironmentId" -ForegroundColor Cyan
    if ($IncludeSSODiagnostics) {
        Write-Host "  Mode: Full Validation + SSO Diagnostics 🔐" -ForegroundColor Yellow
    }
    Write-Host ""

    $suiteResults = @()
    $suiteStartTime = Get-Date
    
    # Determine step count based on options
    $totalSteps = 4
    if ($IncludeSSODiagnostics) { $totalSteps = 5 }

    # ═══════════════════════════════════════════════════════════════════
    # Step 1: Environment Variables Validation
    # ═══════════════════════════════════════════════════════════════════
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "  📋 Step 1/$totalSteps`: Environment Variables" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    $envVarResults = Test-WorkdayEnvironmentVariables -EnvironmentId $EnvironmentId
    $suiteResults += $envVarResults

    # ═══════════════════════════════════════════════════════════════════
    # Step 2: Connection References Validation
    # ═══════════════════════════════════════════════════════════════════
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "  🔗 Step 2/$totalSteps`: Connection References" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    $connRefResults = Test-WorkdayConnectionReferences -EnvironmentId $EnvironmentId
    $suiteResults += $connRefResults

    # ═══════════════════════════════════════════════════════════════════
    # Step 3: Flow Status Validation
    # ═══════════════════════════════════════════════════════════════════
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "  ⚡ Step 3/$totalSteps`: Flow Status" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    $flowResults = Test-WorkdayFlowStatus -EnvironmentId $EnvironmentId
    $suiteResults += $flowResults

    # ═══════════════════════════════════════════════════════════════════
    # Step 4: Connectivity Test (Optional)
    # ═══════════════════════════════════════════════════════════════════
    $connectivityStepNum = if ($IncludeSSODiagnostics) { 4 } else { 4 }
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "  🌐 Step $connectivityStepNum/$totalSteps`: Workday Connectivity" -ForegroundColor Cyan
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
    # Step 5: SSO Configuration Diagnostics (Optional)
    # ═══════════════════════════════════════════════════════════════════
    if ($IncludeSSODiagnostics) {
        Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
        Write-Host "  🔐 Step 5/$totalSteps`: SSO Configuration & Security Domains" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
        
        $ssoParams = @{
            EnvironmentId = $EnvironmentId
        }
        
        if ($GenerateChecklist) {
            $ssoParams.GenerateChecklist = $true
            $ssoParams.OutputPath = $PSScriptRoot
        }
        
        $ssoResults = Test-WorkdaySSOConfiguration @ssoParams
        $suiteResults += $ssoResults
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
    $params = @{
        EnvironmentId = $EnvironmentId
        SkipConnectivityTest = $SkipConnectivityTest
    }
    if ($IncludeSSODiagnostics) { $params.IncludeSSODiagnostics = $true }
    if ($GenerateChecklist) { $params.GenerateChecklist = $true }
    if ($Credential) { $params.Credential = $Credential }
    
    $results = Invoke-WorkdayValidationSuite @params
    
    # Export to CSV if path provided
    if ($ExportPath) {
        $csvPath = if ($ExportPath -match '\.csv$') {
            $ExportPath
        } else {
            $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            Join-Path $ExportPath "WorkdayValidation-$timestamp.csv"
        }
        
        # Ensure directory exists
        $csvDir = Split-Path $csvPath -Parent
        if ($csvDir -and -not (Test-Path $csvDir)) {
            New-Item -ItemType Directory -Path $csvDir -Force | Out-Null
        }
        
        $results | Select-Object CheckpointId, Category, Priority, Status, Result, Remediation | 
            Export-Csv -Path $csvPath -NoTypeInformation
        
        Write-Host ""
        Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║                    RESULTS EXPORTED                          ║" -ForegroundColor Green
        Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        Write-Host "  📄 CSV Report: $csvPath" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Open in Excel to filter/sort results." -ForegroundColor Gray
        Write-Host ""
    } else {
        # No export path - remind user about the option
        Write-Host ""
        Write-Host "💡 Tip: Add -ExportPath to save results as CSV:" -ForegroundColor Yellow
        Write-Host "   .\Invoke-WorkdayValidationSuite.ps1 -EnvironmentId `"$EnvironmentId`" -ExportPath `"C:\Reports\`"" -ForegroundColor DarkGray
        Write-Host ""
    }
}

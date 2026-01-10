<#
.SYNOPSIS
    ESS Connectivity Test Suite - Master Orchestrator
    
.DESCRIPTION
    Runs comprehensive connectivity tests for all ESS external integrations:
    - Workday (ISU and SSO)
    - ServiceNow (REST API)
    - SAP (OData/RFC)
    - Copilot Agent Response Quality
    
    Supports config files, interactive menu, and combined HTML reporting.
    
.PARAMETER ConfigFile
    Path to JSON config file with test credentials/endpoints
    
.PARAMETER TestSuite
    Which tests to run: All, Workday, ServiceNow, SAP, CopilotAgent
    
.PARAMETER OutputPath
    Custom path for HTML report (default: Desktop\ESS-Reports)
    
.EXAMPLE
    .\Invoke-ConnectivitySuite.ps1
    Runs interactive menu to select tests
    
.EXAMPLE
    .\Invoke-ConnectivitySuite.ps1 -ConfigFile .\config\prod-tests.json -TestSuite All
    Runs all tests using production config
    
.EXAMPLE
    .\Invoke-ConnectivitySuite.ps1 -TestSuite Workday
    Runs only Workday tests (ISU + SSO) interactively
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("All", "Workday", "ServiceNow", "SAP", "CopilotAgent", "Interactive")]
    [string]$TestSuite = "Interactive",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "$env:USERPROFILE\Desktop\ESS-Reports"
)

# Script metadata
$ScriptVersion = "1.0.0"
$ScriptDate = "2026-01-10"

# Color coding for output
function Write-TestHeader {
    param([string]$Message)
    Write-Host "`n╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  $($Message.PadRight(67))║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

function Write-TestResult {
    param(
        [string]$TestName,
        [string]$Status,
        [string]$Message,
        [int]$Duration
    )
    
    $statusColor = switch ($Status) {
        "Passed" { "Green" }
        "Failed" { "Red" }
        "Warning" { "Yellow" }
        "Skipped" { "Gray" }
        default { "White" }
    }
    
    Write-Host "  [$Status] " -ForegroundColor $statusColor -NoNewline
    Write-Host "$TestName " -NoNewline
    Write-Host "($Duration ms)" -ForegroundColor Gray
    if ($Message) {
        Write-Host "    → $Message" -ForegroundColor Gray
    }
}

# Load configuration file
function Get-TestConfig {
    param([string]$ConfigPath)
    
    if (-not $ConfigPath) {
        return $null
    }
    
    if (-not (Test-Path $ConfigPath)) {
        Write-Warning "Config file not found: $ConfigPath"
        return $null
    }
    
    try {
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        Write-Host "✓ Loaded config from: $ConfigPath" -ForegroundColor Green
        return $config
    }
    catch {
        Write-Warning "Failed to parse config file: $_"
        return $null
    }
}

# Show interactive menu
function Show-TestMenu {
    Clear-Host
    Write-Host "╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                  ESS CONNECTIVITY TEST SUITE v$ScriptVersion                  ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Select tests to run:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] Workday ISU Authentication (SOAP WS-Security)" -ForegroundColor White
    Write-Host "  [2] Workday SSO Authentication (OAuth Device Code)" -ForegroundColor White
    Write-Host "  [3] ServiceNow Connectivity (REST API)" -ForegroundColor White
    Write-Host "  [4] SAP Connectivity (OData/RFC)" -ForegroundColor White
    Write-Host "  [5] Copilot Agent Response Quality" -ForegroundColor White
    Write-Host ""
    Write-Host "  [A] Run All Tests" -ForegroundColor Green
    Write-Host "  [W] Run All Workday Tests (1+2)" -ForegroundColor Green
    Write-Host "  [Q] Quit" -ForegroundColor Red
    Write-Host ""
    
    do {
        $selection = Read-Host "Enter selection"
        $selection = $selection.ToUpper()
    } until ($selection -in @('1','2','3','4','5','A','W','Q'))
    
    return $selection
}

# Initialize results array
$global:TestResults = @()

# Test runner wrapper
function Invoke-TestWithTiming {
    param(
        [string]$TestName,
        [ScriptBlock]$TestScript,
        [hashtable]$Parameters = @{}
    )
    
    Write-TestHeader $TestName
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $result = & $TestScript @Parameters
        $stopwatch.Stop()
        
        $testResult = [PSCustomObject]@{
            TestName = $TestName
            Status = $result.Status
            Message = $result.Message
            Details = $result.Details
            Duration = $stopwatch.ElapsedMilliseconds
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        $global:TestResults += $testResult
        
        Write-TestResult -TestName $TestName -Status $result.Status -Message $result.Message -Duration $stopwatch.ElapsedMilliseconds
        
        return $testResult
    }
    catch {
        $stopwatch.Stop()
        
        $testResult = [PSCustomObject]@{
            TestName = $TestName
            Status = "Failed"
            Message = $_.Exception.Message
            Details = $_.ScriptStackTrace
            Duration = $stopwatch.ElapsedMilliseconds
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        $global:TestResults += $testResult
        
        Write-TestResult -TestName $TestName -Status "Failed" -Message $_.Exception.Message -Duration $stopwatch.ElapsedMilliseconds
        
        return $testResult
    }
}

# Workday ISU Test
function Test-WorkdayISU {
    param(
        [string]$Username,
        [string]$Password,
        [string]$Tenant
    )
    
    # If parameters not provided, prompt user
    if (-not $Username) {
        $Username = Read-Host "Workday ISU Username"
    }
    if (-not $Password) {
        $Password = Read-Host "Workday ISU Password" -AsSecureString
        $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
    }
    if (-not $Tenant) {
        $Tenant = Read-Host "Workday Tenant"
    }
    
    # Check if Test-WorkdayConnectivity.ps1 exists
    $testScript = Join-Path $PSScriptRoot "..\Test-WorkdayConnectivity.ps1"
    if (-not (Test-Path $testScript)) {
        return @{
            Status = "Skipped"
            Message = "Test-WorkdayConnectivity.ps1 not found"
            Details = "Expected location: $testScript"
        }
    }
    
    # Run the test script
    try {
        $output = & $testScript -Username $Username -Password $Password -Tenant $Tenant 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            return @{
                Status = "Passed"
                Message = "ISU authentication successful"
                Details = ($output | Out-String)
            }
        }
        else {
            return @{
                Status = "Failed"
                Message = "ISU authentication failed"
                Details = ($output | Out-String)
            }
        }
    }
    catch {
        return @{
            Status = "Failed"
            Message = $_.Exception.Message
            Details = $_.ScriptStackTrace
        }
    }
}

# Workday SSO Test
function Test-WorkdaySSO {
    param(
        [string]$Tenant
    )
    
    if (-not $Tenant) {
        $Tenant = Read-Host "Workday Tenant"
    }
    
    $testScript = Join-Path $PSScriptRoot "..\Test-WorkdaySSOConnectivity.ps1"
    if (-not (Test-Path $testScript)) {
        return @{
            Status = "Skipped"
            Message = "Test-WorkdaySSOConnectivity.ps1 not found"
            Details = "Expected location: $testScript"
        }
    }
    
    try {
        $output = & $testScript -Tenant $Tenant 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            return @{
                Status = "Passed"
                Message = "SSO authentication successful"
                Details = ($output | Out-String)
            }
        }
        else {
            return @{
                Status = "Failed"
                Message = "SSO authentication failed"
                Details = ($output | Out-String)
            }
        }
    }
    catch {
        return @{
            Status = "Failed"
            Message = $_.Exception.Message
            Details = $_.ScriptStackTrace
        }
    }
}

# ServiceNow Test
function Test-ServiceNowConnectivity {
    param(
        [string]$Instance,
        [string]$Username,
        [string]$Password
    )
    
    $testScript = Join-Path $PSScriptRoot "Test-ServiceNowConnectivity.ps1"
    if (-not (Test-Path $testScript)) {
        return @{
            Status = "Skipped"
            Message = "Test-ServiceNowConnectivity.ps1 not yet implemented"
            Details = "Will be created in next phase"
        }
    }
    
    try {
        if ($Username -and $Password) {
            $output = & $testScript -Instance $Instance -Username $Username -Password $Password 2>&1
        }
        else {
            $output = & $testScript -Instance $Instance 2>&1
        }
        
        if ($LASTEXITCODE -eq 0) {
            return @{
                Status = "Passed"
                Message = "ServiceNow connectivity successful"
                Details = ($output | Out-String)
            }
        }
        else {
            return @{
                Status = "Failed"
                Message = "ServiceNow connectivity failed"
                Details = ($output | Out-String)
            }
        }
    }
    catch {
        return @{
            Status = "Failed"
            Message = $_.Exception.Message
            Details = $_.ScriptStackTrace
        }
    }
}

# SAP Test
function Test-SAPConnectivity {
    param(
        [string]$Endpoint,
        [string]$Username,
        [string]$Password
    )
    
    return @{
        Status = "Skipped"
        Message = "SAP connectivity test not yet implemented"
        Details = "Will be created in next phase"
    }
}

# Copilot Agent Test
function Test-CopilotAgent {
    param(
        [string]$AgentId,
        [string]$EnvironmentId
    )
    
    $testScript = Join-Path $PSScriptRoot "Test-CopilotAgentResponse.ps1"
    if (-not (Test-Path $testScript)) {
        return @{
            Status = "Skipped"
            Message = "Test-CopilotAgentResponse.ps1 not yet implemented"
            Details = "Will be created in next phase"
        }
    }
    
    try {
        if ($AgentId -and $EnvironmentId) {
            $output = & $testScript -AgentId $AgentId -EnvironmentId $EnvironmentId 2>&1
        }
        else {
            $output = & $testScript 2>&1
        }
        
        if ($LASTEXITCODE -eq 0) {
            return @{
                Status = "Passed"
                Message = "Copilot agent responding correctly"
                Details = ($output | Out-String)
            }
        }
        else {
            return @{
                Status = "Failed"
                Message = "Copilot agent test failed"
                Details = ($output | Out-String)
            }
        }
    }
    catch {
        return @{
            Status = "Failed"
            Message = $_.Exception.Message
            Details = $_.ScriptStackTrace
        }
    }
}

# Generate HTML report
function New-ConnectivityReport {
    param([array]$Results, [string]$OutputDir)
    
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $reportPath = Join-Path $OutputDir "ESS-Connectivity-Report-$timestamp.html"
    
    $passCount = ($Results | Where-Object { $_.Status -eq "Passed" }).Count
    $failCount = ($Results | Where-Object { $_.Status -eq "Failed" }).Count
    $warnCount = ($Results | Where-Object { $_.Status -eq "Warning" }).Count
    $skipCount = ($Results | Where-Object { $_.Status -eq "Skipped" }).Count
    $totalCount = $Results.Count
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ESS Connectivity Test Report - $(Get-Date -Format "yyyy-MM-dd")</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            margin: 0 0 10px 0;
            font-size: 2.5em;
        }
        .header p {
            margin: 5px 0;
            opacity: 0.9;
        }
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            padding: 30px;
            background: #f8f9fa;
        }
        .summary-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            text-align: center;
        }
        .summary-card h3 {
            margin: 0 0 10px 0;
            font-size: 2em;
            font-weight: bold;
        }
        .summary-card p {
            margin: 0;
            color: #666;
            font-size: 0.9em;
            text-transform: uppercase;
        }
        .passed { color: #28a745; }
        .failed { color: #dc3545; }
        .warning { color: #ffc107; }
        .skipped { color: #6c757d; }
        .results {
            padding: 30px;
        }
        .test-item {
            background: white;
            border: 1px solid #dee2e6;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 15px;
            transition: all 0.3s ease;
        }
        .test-item:hover {
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            transform: translateY(-2px);
        }
        .test-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }
        .test-name {
            font-size: 1.2em;
            font-weight: bold;
        }
        .test-status {
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9em;
            font-weight: bold;
            text-transform: uppercase;
        }
        .status-passed {
            background: #d4edda;
            color: #155724;
        }
        .status-failed {
            background: #f8d7da;
            color: #721c24;
        }
        .status-warning {
            background: #fff3cd;
            color: #856404;
        }
        .status-skipped {
            background: #e2e3e5;
            color: #383d41;
        }
        .test-details {
            color: #666;
            font-size: 0.95em;
            margin: 5px 0;
        }
        .test-meta {
            display: flex;
            justify-content: space-between;
            font-size: 0.85em;
            color: #999;
            margin-top: 10px;
        }
        .details-section {
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            padding: 15px;
            margin-top: 10px;
            border-radius: 4px;
            font-family: 'Courier New', monospace;
            font-size: 0.85em;
            white-space: pre-wrap;
            max-height: 300px;
            overflow-y: auto;
        }
        .footer {
            text-align: center;
            padding: 20px;
            color: #666;
            font-size: 0.9em;
            background: #f8f9fa;
            border-top: 1px solid #dee2e6;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔌 ESS Connectivity Test Report</h1>
            <p>Generated: $(Get-Date -Format "MMMM dd, yyyy 'at' HH:mm:ss")</p>
            <p>Test Suite Version: $ScriptVersion</p>
        </div>
        
        <div class="summary">
            <div class="summary-card">
                <h3 class="passed">$passCount</h3>
                <p>Passed</p>
            </div>
            <div class="summary-card">
                <h3 class="failed">$failCount</h3>
                <p>Failed</p>
            </div>
            <div class="summary-card">
                <h3 class="warning">$warnCount</h3>
                <p>Warnings</p>
            </div>
            <div class="summary-card">
                <h3 class="skipped">$skipCount</h3>
                <p>Skipped</p>
            </div>
            <div class="summary-card">
                <h3>$totalCount</h3>
                <p>Total Tests</p>
            </div>
        </div>
        
        <div class="results">
            <h2>Test Results</h2>
"@
    
    foreach ($result in $Results) {
        $statusClass = "status-$($result.Status.ToLower())"
        
        $html += @"
            <div class="test-item">
                <div class="test-header">
                    <div class="test-name">$($result.TestName)</div>
                    <div class="test-status $statusClass">$($result.Status)</div>
                </div>
                <div class="test-details">$($result.Message)</div>
                <div class="test-meta">
                    <span>⏱️ Duration: $($result.Duration) ms</span>
                    <span>🕐 Timestamp: $($result.Timestamp)</span>
                </div>
"@
        
        if ($result.Details) {
            $html += @"
                <div class="details-section">$([System.Web.HttpUtility]::HtmlEncode($result.Details))</div>
"@
        }
        
        $html += @"
            </div>
"@
    }
    
    $html += @"
        </div>
        
        <div class="footer">
            <p>ESS Connectivity Test Suite v$ScriptVersion | © 2026 Your Organization</p>
            <p>For support, contact your ESS deployment team</p>
        </div>
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-Host "`n✓ Report generated: $reportPath" -ForegroundColor Green
    
    return $reportPath
}

# Main execution
Write-Host "╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         ESS CONNECTIVITY TEST SUITE v$ScriptVersion - $(Get-Date -Format 'yyyy-MM-dd')          ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# Load config if provided
$config = $null
if ($ConfigFile) {
    $config = Get-TestConfig -ConfigPath $ConfigFile
}

# Determine which tests to run
$testsToRun = @()

if ($TestSuite -eq "Interactive") {
    $selection = Show-TestMenu
    
    switch ($selection) {
        '1' { $testsToRun = @('WorkdayISU') }
        '2' { $testsToRun = @('WorkdaySSO') }
        '3' { $testsToRun = @('ServiceNow') }
        '4' { $testsToRun = @('SAP') }
        '5' { $testsToRun = @('CopilotAgent') }
        'A' { $testsToRun = @('WorkdayISU', 'WorkdaySSO', 'ServiceNow', 'SAP', 'CopilotAgent') }
        'W' { $testsToRun = @('WorkdayISU', 'WorkdaySSO') }
        'Q' { 
            Write-Host "`nExiting..." -ForegroundColor Yellow
            exit 0
        }
    }
}
else {
    switch ($TestSuite) {
        'All' { $testsToRun = @('WorkdayISU', 'WorkdaySSO', 'ServiceNow', 'SAP', 'CopilotAgent') }
        'Workday' { $testsToRun = @('WorkdayISU', 'WorkdaySSO') }
        'ServiceNow' { $testsToRun = @('ServiceNow') }
        'SAP' { $testsToRun = @('SAP') }
        'CopilotAgent' { $testsToRun = @('CopilotAgent') }
    }
}

Write-Host "`nStarting test execution..." -ForegroundColor Yellow
Write-Host "Tests to run: $($testsToRun -join ', ')" -ForegroundColor Gray
Write-Host ""

# Run selected tests
foreach ($test in $testsToRun) {
    switch ($test) {
        'WorkdayISU' {
            $params = @{}
            if ($config -and $config.workday) {
                $params.Username = $config.workday.isu.username
                $params.Password = $config.workday.isu.password
                $params.Tenant = $config.workday.tenant
            }
            Invoke-TestWithTiming -TestName "Workday ISU Authentication" -TestScript { Test-WorkdayISU @params } -Parameters $params
        }
        'WorkdaySSO' {
            $params = @{}
            if ($config -and $config.workday) {
                $params.Tenant = $config.workday.tenant
            }
            Invoke-TestWithTiming -TestName "Workday SSO Authentication" -TestScript { Test-WorkdaySSO @params } -Parameters $params
        }
        'ServiceNow' {
            $params = @{}
            if ($config -and $config.servicenow) {
                $params.Instance = $config.servicenow.instance
                $params.Username = $config.servicenow.username
                $params.Password = $config.servicenow.password
            }
            Invoke-TestWithTiming -TestName "ServiceNow Connectivity" -TestScript { Test-ServiceNowConnectivity @params } -Parameters $params
        }
        'SAP' {
            $params = @{}
            if ($config -and $config.sap) {
                $params.Endpoint = $config.sap.endpoint
                $params.Username = $config.sap.username
                $params.Password = $config.sap.password
            }
            Invoke-TestWithTiming -TestName "SAP Connectivity" -TestScript { Test-SAPConnectivity @params } -Parameters $params
        }
        'CopilotAgent' {
            $params = @{}
            if ($config -and $config.copilot) {
                $params.AgentId = $config.copilot.agentId
                $params.EnvironmentId = $config.copilot.environmentId
            }
            Invoke-TestWithTiming -TestName "Copilot Agent Response Quality" -TestScript { Test-CopilotAgent @params } -Parameters $params
        }
    }
}

# Generate report
Write-Host "`n" + ("═" * 75) -ForegroundColor Cyan
Write-Host "Test execution complete!" -ForegroundColor Green
Write-Host ("═" * 75) -ForegroundColor Cyan

$reportPath = New-ConnectivityReport -Results $global:TestResults -OutputDir $OutputPath

# Summary
$passCount = ($global:TestResults | Where-Object { $_.Status -eq "Passed" }).Count
$failCount = ($global:TestResults | Where-Object { $_.Status -eq "Failed" }).Count
$warnCount = ($global:TestResults | Where-Object { $_.Status -eq "Warning" }).Count
$skipCount = ($global:TestResults | Where-Object { $_.Status -eq "Skipped" }).Count

Write-Host "`nSummary:" -ForegroundColor Yellow
Write-Host "  ✓ Passed:  $passCount" -ForegroundColor Green
Write-Host "  ✗ Failed:  $failCount" -ForegroundColor Red
Write-Host "  ⚠ Warning: $warnCount" -ForegroundColor Yellow
Write-Host "  ⊘ Skipped: $skipCount" -ForegroundColor Gray

Write-Host "`nOpening report..." -ForegroundColor Cyan
Start-Process $reportPath

Write-Host "`n✓ Done! Press any key to exit..." -ForegroundColor Green
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

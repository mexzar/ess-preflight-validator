<#
.SYNOPSIS
    ESS Phased Deployment Wizard - Step-by-step validation aligned to Microsoft's deployment guide
    
.DESCRIPTION
    Guides users through ESS deployment in 6 phases with blocking gates and inline remediation:
    
    Phase 1: Prerequisites - Licenses, permissions, PowerShell modules
    Phase 2: Environment Setup - Power Platform environment, DLP policies, Dataverse
    Phase 3: External Systems - Workday, ServiceNow, SAP connectivity
    Phase 4: ESS Agent Configuration - Agent creation, topics, content
    Phase 5: Testing & UAT - Functional testing, user acceptance
    Phase 6: Production Readiness - Performance, security, monitoring
    
    Each phase must pass before progressing to the next. Progress is saved and can be resumed.
    
.PARAMETER StartFromPhase
    Resume from specific phase (1-6)
    
.PARAMETER ResetProgress
    Clear saved progress and start fresh
    
.PARAMETER AutoFix
    Attempt automatic remediation where possible
    
.EXAMPLE
    .\Start-ESSDeployment.ps1
    Start deployment wizard from Phase 1 or resume from saved progress
    
.EXAMPLE
    .\Start-ESSDeployment.ps1 -StartFromPhase 3
    Jump to Phase 3 (External Systems) if previous phases are complete
    
.EXAMPLE
    .\Start-ESSDeployment.ps1 -ResetProgress
    Clear all saved progress and start from scratch
    
.NOTES
    Author: ESS Pre-flight Validator
    Version: 1.0.0
    Requires: ESS-Validator.psm1, PowerShell 7.0+
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 6)]
    [int]$StartFromPhase = 0,
    
    [switch]$ResetProgress,
    [switch]$AutoFix
)

#Requires -Version 7.0

# Import required modules
Write-Verbose "Loading required modules..."

# Import ESS-Validator module
$modulePath = Join-Path $PSScriptRoot "ESS-Validator.psm1"
if (-not (Test-Path $modulePath)) {
    Write-Host "❌ Error: ESS-Validator.psm1 not found" -ForegroundColor Red
    exit 1
}

Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Import Microsoft Graph module (should already be installed)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Host "⚠️  Microsoft.Graph.Authentication module not found - some features may not work" -ForegroundColor Yellow
}

# Import Power Platform module
if (Get-Module -ListAvailable -Name Microsoft.PowerApps.Administration.PowerShell) {
    Import-Module Microsoft.PowerApps.Administration.PowerShell -WarningAction SilentlyContinue
} else {
    Write-Host "⚠️  Microsoft.PowerApps.Administration.PowerShell module not found" -ForegroundColor Yellow
    Write-Host "    Install with: Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Scope CurrentUser" -ForegroundColor Gray
}

# Progress storage
$progressDir = Join-Path $HOME ".ess-validator"
$progressPath = Join-Path $progressDir "deployment-state.json"

# Phase definitions
$phases = @(
    @{
        Number = 1
        Name = "Prerequisites"
        Description = "Validate licenses, permissions, and PowerShell modules"
        Checkpoints = @("PRE-001", "PRE-002", "PRE-003", "PRE-004", "PRE-005")
        BlockingIssues = @("PRE-001", "PRE-002")  # Must pass to proceed
    },
    @{
        Number = 2
        Name = "Environment Setup"
        Description = "Configure Power Platform environment, DLP policies, and Dataverse"
        Checkpoints = @("ENV-001", "ENV-002", "ENV-003", "ENV-004", "ENV-005", "ENV-006", "ENV-007", "ENV-008")
        BlockingIssues = @("ENV-001", "ENV-003", "ENV-008")
    },
    @{
        Number = 3
        Name = "External Systems"
        Description = "Validate connectivity to Workday, ServiceNow, and SAP"
        Checkpoints = @("EXT-001", "EXT-002", "EXT-003", "EXT-004", "EXT-005")
        BlockingIssues = @("EXT-001")  # At least one system must be configured
    },
    @{
        Number = 4
        Name = "ESS Agent Configuration"
        Description = "Configure Copilot agent, topics, and content"
        Checkpoints = @("CON-001", "CON-002", "CON-003", "TOP-001", "TOP-002", "TOP-003", "CFG-001", "CFG-002")
        BlockingIssues = @("CON-001", "TOP-001", "CFG-001")
    },
    @{
        Number = 5
        Name = "Testing & UAT"
        Description = "Functional testing and user acceptance validation"
        Checkpoints = @("TEST-001", "TEST-002", "TEST-003", "TEST-004")
        BlockingIssues = @("TEST-001", "TEST-002")
    },
    @{
        Number = 6
        Name = "Production Readiness"
        Description = "Final production validation and go-live checklist"
        Checkpoints = @("PUB-001", "PUB-002", "PUB-003", "DEP-001", "DEP-002", "DEP-003")
        BlockingIssues = @("PUB-001", "DEP-001")
    }
)

#region Helper Functions

function Show-DeploymentBanner {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║        ESS PHASED DEPLOYMENT WIZARD - v1.0.0                           ║" -ForegroundColor Cyan
    Write-Host "║        Step-by-step validation aligned to deployment guide            ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Get-UserConfirmation {
    param(
        [string]$Prompt,
        [bool]$Default = $true
    )
    
    $defaultText = if ($Default) { "[Y/n]" } else { "[y/N]" }
    $response = Read-Host "$Prompt $defaultText"
    
    if ([string]::IsNullOrWhiteSpace($response)) {
        return $Default
    }
    
    return $response -match '^[Yy]'
}

function Get-CurrentUserContext {
    Write-Host "🔍 Detecting your user context..." -ForegroundColor Cyan
    
    try {
        # Try to get current Graph context
        $context = Get-MgContext -ErrorAction SilentlyContinue
        
        if ($context) {
            return @{
                UserPrincipalName = $context.Account
                TenantId = $context.TenantId
                Connected = $true
            }
        }
        
        # Not connected, will need to connect
        return @{
            UserPrincipalName = $env:USERNAME + "@" + $env:USERDNSDOMAIN
            TenantId = $null
            Connected = $false
        }
    }
    catch {
        return @{
            UserPrincipalName = $env:USERNAME
            TenantId = $null
            Connected = $false
        }
    }
}

function Test-MyPermissions {
    param(
        [string]$TenantId
    )
    
    Write-Host ""
    Write-Host "🔐 Checking YOUR permissions..." -ForegroundColor Cyan
    
    $permissions = @{
        GlobalAdmin = $false
        PowerPlatformAdmin = $false
        EnvironmentMaker = $false
        CopilotStudioLicense = $false
    }
    
    try {
        # Connect if needed
        $context = Get-MgContext -ErrorAction SilentlyContinue
        if (-not $context) {
            if ($TenantId) {
                Connect-MgGraph -TenantId $TenantId -Scopes "User.Read.All", "Directory.Read.All", "RoleManagement.Read.All" -NoWelcome
            } else {
                Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All", "RoleManagement.Read.All" -NoWelcome
            }
        }
        
        # Get current user
        $me = Get-MgUser -UserId (Get-MgContext).Account -ErrorAction SilentlyContinue
        
        if ($me) {
            # Check Global Admin role
            $globalAdminRole = Get-MgDirectoryRole -Filter "displayName eq 'Global Administrator'" -ErrorAction SilentlyContinue
            if ($globalAdminRole) {
                $members = Get-MgDirectoryRoleMember -DirectoryRoleId $globalAdminRole.Id -ErrorAction SilentlyContinue
                $permissions.GlobalAdmin = $members.Id -contains $me.Id
            }
            
            # Check Power Platform Admin role
            $ppAdminRole = Get-MgDirectoryRole -Filter "displayName eq 'Power Platform Administrator'" -ErrorAction SilentlyContinue
            if ($ppAdminRole) {
                $members = Get-MgDirectoryRoleMember -DirectoryRoleId $ppAdminRole.Id -ErrorAction SilentlyContinue
                $permissions.PowerPlatformAdmin = $members.Id -contains $me.Id
            }
            
            # Check licenses (simplified - check for any Power Apps/Copilot license)
            $licenses = Get-MgUserLicenseDetail -UserId $me.Id -ErrorAction SilentlyContinue
            $permissions.CopilotStudioLicense = $licenses.SkuPartNumber -match 'POWER.*APPS|COPILOT'
        }
        
        # Display results
        $checkMark = if ($permissions.GlobalAdmin) { "✓" } else { "✗" }
        $color = if ($permissions.GlobalAdmin) { "Green" } else { "Yellow" }
        Write-Host "  $checkMark Global Admin: " -NoNewline -ForegroundColor $color
        Write-Host $permissions.GlobalAdmin
        
        $checkMark = if ($permissions.PowerPlatformAdmin) { "✓" } else { "✗" }
        $color = if ($permissions.PowerPlatformAdmin) { "Green" } else { "Yellow" }
        Write-Host "  $checkMark Power Platform Admin: " -NoNewline -ForegroundColor $color
        Write-Host $permissions.PowerPlatformAdmin
        
        $checkMark = if ($permissions.CopilotStudioLicense) { "✓" } else { "✗" }
        $color = if ($permissions.CopilotStudioLicense) { "Green" } else { "Yellow" }
        Write-Host "  $checkMark Copilot Studio License: " -NoNewline -ForegroundColor $color
        Write-Host $permissions.CopilotStudioLicense
        
        Write-Host ""
    }
    catch {
        Write-Host "  ⚠️  Unable to check permissions: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host ""
    }
    
    return $permissions
}

function Initialize-DeploymentSession {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Step 1: User Context & Authentication" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # Get current user context
    $userContext = Get-CurrentUserContext
    
    Write-Host "  Detected account: " -NoNewline
    Write-Host $userContext.UserPrincipalName -ForegroundColor Cyan
    
    if ($userContext.TenantId) {
        Write-Host "  Tenant ID: " -NoNewline
        Write-Host $userContext.TenantId.Substring(0, 8) -NoNewline
        Write-Host "..." -ForegroundColor DarkGray
    }
    
    Write-Host ""
    
    # Ask if this is correct
    $accountCorrect = Get-UserConfirmation "Is this the correct account for deployment?" $true
    
    $accountSwitched = $false
    
    if (-not $accountCorrect) {
        Write-Host ""
        Write-Host "Please enter the account you want to use:" -ForegroundColor Yellow
        $customAccount = Read-Host "User Principal Name (e.g., admin@contoso.com)"
        
        if (-not [string]::IsNullOrWhiteSpace($customAccount)) {
            Write-Host ""
            Write-Host "Switching to account: " -NoNewline
            Write-Host $customAccount -ForegroundColor Cyan
            
            # Disconnect current sessions
            try {
                Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
            } catch {}
            
            # Force new connection with specified account using -AccountId
            Write-Host "🔐 Connecting to Microsoft Graph as $customAccount..." -ForegroundColor Cyan
            Write-Host "  → You will be prompted to sign in with this account" -ForegroundColor Yellow
            try {
                Connect-MgGraph -AccountId $customAccount -Scopes "User.Read.All", "Directory.Read.All", "RoleManagement.Read.All", "Organization.Read.All" -NoWelcome -ErrorAction Stop
                
                # Verify we're connected as the requested account
                $newContext = Get-MgContext
                if ($newContext.Account -eq $customAccount) {
                    $userContext.UserPrincipalName = $newContext.Account
                    $userContext.TenantId = $newContext.TenantId
                    $userContext.Connected = $true
                    $accountSwitched = $true
                    
                    Write-Host "  ✓ Connected successfully as $($newContext.Account)!" -ForegroundColor Green
                }
                else {
                    Write-Host "  ⚠ Connected as $($newContext.Account) instead of $customAccount" -ForegroundColor Yellow
                    $userContext.UserPrincipalName = $newContext.Account
                    $userContext.TenantId = $newContext.TenantId
                    $userContext.Connected = $true
                }
            }
            catch {
                Write-Host "  ✗ Failed to connect: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "  ⚠ Continuing with current context..." -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host ""
    
    # Ensure Microsoft Graph is connected
    $context = Get-MgContext -ErrorAction SilentlyContinue
    
    if (-not $context) {
        Write-Host "🔐 Connecting to Microsoft Graph..." -ForegroundColor Cyan
        try {
            Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All", "RoleManagement.Read.All" -NoWelcome -ErrorAction Stop
            Write-Host "  ✓ Connected to Microsoft Graph" -ForegroundColor Green
        }
        catch {
            Write-Host "  ✗ Failed to connect to Microsoft Graph: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "  ⚠ Some validations may fail without Graph connection" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "  ✓ Microsoft Graph connected as: $($context.Account)" -ForegroundColor Green
    }
    
    # Check permissions
    $permissions = Test-MyPermissions -TenantId $userContext.TenantId
    
    # Check if Power Platform is connected
    Write-Host "🔌 Connecting to Power Platform..." -ForegroundColor Cyan
    
    # Check if module is available
    if (-not (Get-Command -Name Get-PowerAppAccount -ErrorAction SilentlyContinue)) {
        Write-Host "  ⚠ Power Platform module not loaded" -ForegroundColor Yellow
        Write-Host "    Install with: Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Scope CurrentUser" -ForegroundColor Gray
        Write-Host "  ⚠ Environment validation will be limited" -ForegroundColor Yellow
    }
    else {
        try {
            $ppAccounts = Get-PowerAppAccount -ErrorAction SilentlyContinue
            if (-not $ppAccounts -or $accountSwitched) {
                Add-PowerAppsAccount -ErrorAction Stop
                Write-Host "  ✓ Connected to Power Platform" -ForegroundColor Green
            }
            else {
                Write-Host "  ✓ Power Platform already connected" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "  ⚠ Power Platform connection issue: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "  ⚠ Environment validation may fail" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "  ✓ Session initialized successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    return @{
        UserContext = $userContext
        Permissions = $permissions
    }
}

function Get-DeploymentProgress {
    if (-not (Test-Path $progressPath)) {
        return $null
    }
    
    try {
        $progress = Get-Content $progressPath -Raw | ConvertFrom-Json
        
        # Convert PhaseResults from PSCustomObject to hashtable if needed
        if ($progress.PhaseResults -and $progress.PhaseResults -isnot [hashtable]) {
            $hashTable = @{}
            $progress.PhaseResults.PSObject.Properties | ForEach-Object {
                $hashTable[$_.Name] = $_.Value
            }
            $progress.PhaseResults = $hashTable
        }
        
        return $progress
    }
    catch {
        return $null
    }
}

function Save-DeploymentProgress {
    param(
        [int]$CurrentPhase,
        $PhaseResults,
        [string]$EnvironmentId,
        [string]$TenantId
    )
    
    if (-not (Test-Path $progressDir)) {
        New-Item -ItemType Directory -Path $progressDir -Force | Out-Null
    }
    
    $progress = @{
        CurrentPhase = $CurrentPhase
        LastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        EnvironmentId = $EnvironmentId
        TenantId = $TenantId
        PhaseResults = $PhaseResults
    }
    
    $progress | ConvertTo-Json -Depth 10 | Out-File -FilePath $progressPath -Encoding UTF8
    Write-Verbose "Progress saved to: $progressPath"
}

function Clear-DeploymentProgress {
    if (Test-Path $progressPath) {
        Remove-Item $progressPath -Force
        Write-Host "✓ Deployment progress cleared" -ForegroundColor Green
    }
}

function Show-PhaseMenu {
    param([array]$Phases, [object]$Progress)
    
    Show-DeploymentBanner
    
    Write-Host "╔════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║                        DEPLOYMENT PHASES                               ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($phase in $Phases) {
        $phaseNum = $phase.Number
        $phaseName = $phase.Name
        $phaseDesc = $phase.Description
        
        # Determine phase status
        $status = "⚪ Not Started"
        $statusColor = "Gray"
        
        if ($Progress -and $Progress.PhaseResults -and $Progress.PhaseResults."Phase$phaseNum") {
            $phaseResult = $Progress.PhaseResults."Phase$phaseNum"
            if ($phaseResult.Status -eq "Passed") {
                $status = "✓ Complete"
                $statusColor = "Green"
            }
            elseif ($phaseResult.Status -eq "Blocked") {
                $status = "🔒 Blocked"
                $statusColor = "Red"
            }
            elseif ($phaseResult.Status -eq "InProgress") {
                $status = "⏳ In Progress"
                $statusColor = "Yellow"
            }
        }
        
        Write-Host "  Phase ${phaseNum}: " -NoNewline -ForegroundColor Cyan
        Write-Host "$phaseName " -NoNewline -ForegroundColor White
        Write-Host "[$status]" -ForegroundColor $statusColor
        Write-Host "           $phaseDesc" -ForegroundColor Gray
        Write-Host ""
    }
    
    if ($Progress) {
        Write-Host "Last saved: " -NoNewline -ForegroundColor Yellow
        Write-Host $Progress.LastUpdated -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select phase to run (or press Enter to continue from last position):" -ForegroundColor Yellow
    Write-Host "  [1-6] - Run specific phase" -ForegroundColor White
    Write-Host "  [A]   - Run all phases sequentially" -ForegroundColor Green
    Write-Host "  [R]   - Reset progress and start fresh" -ForegroundColor Yellow
    Write-Host "  [Q]   - Quit" -ForegroundColor Red
    Write-Host ""
    
    $selection = Read-Host "Selection"
    
    return $selection
}

function Invoke-PhaseValidation {
    param(
        [hashtable]$Phase,
        [string]$EnvironmentId
    )
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  PHASE $($Phase.Number): $($Phase.Name.ToUpper().PadRight(64))║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  $($Phase.Description)" -ForegroundColor Gray
    Write-Host ""
    
    # Run validation based on phase
    $results = @()
    
    switch ($Phase.Number) {
        1 {
            # Phase 1: Prerequisites
            Write-Host "  Validating prerequisites..." -ForegroundColor Yellow
            $results = Test-ESSPrerequisites
        }
        2 {
            # Phase 2: Environment Setup
            Write-Host "  Validating environment setup..." -ForegroundColor Yellow
            if (-not $EnvironmentId) {
                Write-Host "  ⚠ Environment ID required for Phase 2" -ForegroundColor Yellow
                return @{
                    Status = "Blocked"
                    Message = "Environment ID not provided"
                    Results = @()
                }
            }
            $results = Test-ESSEnvironment -EnvironmentId $EnvironmentId
        }
        3 {
            # Phase 3: External Systems
            Write-Host "  Validating external system connectivity..." -ForegroundColor Yellow
            if (-not $EnvironmentId) {
                Write-Host "  ⚠ Environment ID required for Phase 3" -ForegroundColor Yellow
                return @{
                    Status = "Blocked"
                    Message = "Environment ID not provided"
                    Results = @()
                }
            }
            $results = Test-ESSExternalSystems -EnvironmentId $EnvironmentId
        }
        4 {
            # Phase 4: ESS Agent Configuration
            Write-Host "  Validating agent configuration..." -ForegroundColor Yellow
            $contentResults = Test-ESSContent -EnvironmentId $EnvironmentId
            $topicResults = Test-ESSTopics -EnvironmentId $EnvironmentId
            $configResults = Test-ESSConfiguration -EnvironmentId $EnvironmentId
            $results = $contentResults + $topicResults + $configResults
        }
        5 {
            # Phase 5: Testing & UAT
            Write-Host "  Running test scenarios..." -ForegroundColor Yellow
            Write-Host "  Note: This phase requires manual testing validation" -ForegroundColor Gray
            
            # Placeholder for testing phase - would integrate with Test-CopilotAgentResponse.ps1
            $results = @(
                [PSCustomObject]@{
                    CheckpointId = "TEST-001"
                    Category = "Testing"
                    Priority = "Critical"
                    Status = "NotConfigured"
                    Result = "Manual testing required"
                    Remediation = "Run Test-CopilotAgentResponse.ps1 to validate agent responses"
                }
            )
        }
        6 {
            # Phase 6: Production Readiness
            Write-Host "  Validating production readiness..." -ForegroundColor Yellow
            $pubResults = Test-ESSPublishing
            $depResults = Test-ESSDeploymentReadiness -Scope Quick -EnvironmentId $EnvironmentId
            $results = $pubResults + $depResults
        }
    }
    
    # Filter results to phase checkpoints
    $phaseCheckpoints = $Phase.Checkpoints
    $filteredResults = $results | Where-Object { $_.CheckpointId -in $phaseCheckpoints }
    
    # Analyze results
    $passed = ($filteredResults | Where-Object { $_.Status -eq 'Passed' }).Count
    $failed = ($filteredResults | Where-Object { $_.Status -eq 'Failed' }).Count
    $warnings = ($filteredResults | Where-Object { $_.Status -eq 'Warning' }).Count
    
    # Check for blocking issues
    $blockingIssues = $filteredResults | Where-Object { 
        $_.CheckpointId -in $Phase.BlockingIssues -and $_.Status -eq 'Failed' 
    }
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Phase $($Phase.Number) Results:" -ForegroundColor Yellow
    Write-Host "  ✓ Passed:   $passed" -ForegroundColor Green
    Write-Host "  ✗ Failed:   $failed" -ForegroundColor Red
    Write-Host "  ⚠ Warnings: $warnings" -ForegroundColor Yellow
    Write-Host ""
    
    # Display results
    foreach ($result in $filteredResults) {
        $icon = switch ($result.Status) {
            "Passed" { "✓" }
            "Failed" { "✗" }
            "Warning" { "⚠" }
            "NotConfigured" { "○" }
        }
        
        $color = switch ($result.Status) {
            "Passed" { "Green" }
            "Failed" { "Red" }
            "Warning" { "Yellow" }
            "NotConfigured" { "Gray" }
        }
        
        Write-Host "  $icon $($result.CheckpointId): " -NoNewline -ForegroundColor $color
        Write-Host $result.Result -ForegroundColor White
        
        if ($result.Status -ne "Passed") {
            Write-Host "    → $($result.Remediation)" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    
    # Determine phase status
    if ($blockingIssues.Count -gt 0) {
        Write-Host "🔒 PHASE BLOCKED - Critical issues must be resolved before continuing" -ForegroundColor Red
        Write-Host ""
        Write-Host "Blocking Issues:" -ForegroundColor Yellow
        foreach ($issue in $blockingIssues) {
            Write-Host "  ✗ $($issue.CheckpointId): $($issue.Result)" -ForegroundColor Red
            Write-Host "    Fix: $($issue.Remediation)" -ForegroundColor Yellow
        }
        
        return @{
            Status = "Blocked"
            Message = "Critical validation failures detected"
            Results = $filteredResults
            BlockingIssues = $blockingIssues
        }
    }
    elseif ($failed -gt 0) {
        Write-Host "⚠ PHASE INCOMPLETE - Some checks failed but can proceed with caution" -ForegroundColor Yellow
        
        return @{
            Status = "Warning"
            Message = "Phase completed with warnings"
            Results = $filteredResults
        }
    }
    else {
        Write-Host "✓ PHASE COMPLETE - All critical checks passed!" -ForegroundColor Green
        
        return @{
            Status = "Passed"
            Message = "Phase completed successfully"
            Results = $filteredResults
        }
    }
}

function Show-PhaseReport {
    param([hashtable]$PhaseResult, [hashtable]$Phase)
    
    # Generate simple HTML report for phase
    $reportDir = Join-Path $env:USERPROFILE "Desktop\ESS-Reports\Deployment"
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $reportPath = Join-Path $reportDir "Phase-$($Phase.Number)-$($Phase.Name.Replace(' ', ''))-$timestamp.html"
    
    $passed = ($PhaseResult.Results | Where-Object { $_.Status -eq 'Passed' }).Count
    $failed = ($PhaseResult.Results | Where-Object { $_.Status -eq 'Failed' }).Count
    $warnings = ($PhaseResult.Results | Where-Object { $_.Status -eq 'Warning' }).Count
    
    $statusColor = switch ($PhaseResult.Status) {
        "Passed" { "#28a745" }
        "Warning" { "#ffc107" }
        "Blocked" { "#dc3545" }
    }
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Phase $($Phase.Number) - $($Phase.Name) Report</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 20px; background: #f5f5f5; }
        .header { background: $statusColor; color: white; padding: 30px; border-radius: 10px; text-align: center; }
        .content { background: white; padding: 30px; margin: 20px 0; border-radius: 10px; }
        .summary { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; margin: 20px 0; }
        .summary-card { text-align: center; padding: 20px; border-radius: 8px; }
        .passed { background: #d4edda; color: #155724; }
        .failed { background: #f8d7da; color: #721c24; }
        .warning { background: #fff3cd; color: #856404; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th { background: #495057; color: white; padding: 12px; text-align: left; }
        td { padding: 12px; border-bottom: 1px solid #ddd; }
        .status-passed { color: #28a745; font-weight: bold; }
        .status-failed { color: #dc3545; font-weight: bold; }
        .status-warning { color: #ffc107; font-weight: bold; }
        .next-steps { background: #e7f3ff; padding: 20px; border-left: 4px solid #0078d4; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Phase $($Phase.Number): $($Phase.Name)</h1>
        <h2>$($PhaseResult.Status.ToUpper())</h2>
        <p>$(Get-Date -Format 'MMMM dd, yyyy HH:mm:ss')</p>
    </div>
    
    <div class="content">
        <h2>Phase Summary</h2>
        <p>$($Phase.Description)</p>
        
        <div class="summary">
            <div class="summary-card passed">
                <h3>$passed</h3>
                <p>Passed</p>
            </div>
            <div class="summary-card failed">
                <h3>$failed</h3>
                <p>Failed</p>
            </div>
            <div class="summary-card warning">
                <h3>$warnings</h3>
                <p>Warnings</p>
            </div>
        </div>
        
        <h2>Checkpoint Results</h2>
        <table>
            <thead>
                <tr>
                    <th>Checkpoint</th>
                    <th>Priority</th>
                    <th>Status</th>
                    <th>Result</th>
                    <th>Remediation</th>
                </tr>
            </thead>
            <tbody>
"@
    
    foreach ($result in $PhaseResult.Results) {
        $statusClass = "status-$($result.Status.ToLower())"
        $html += @"
                <tr>
                    <td><strong>$($result.CheckpointId)</strong></td>
                    <td>$($result.Priority)</td>
                    <td class="$statusClass">$($result.Status)</td>
                    <td>$($result.Result)</td>
                    <td>$($result.Remediation)</td>
                </tr>
"@
    }
    
    $html += @"
            </tbody>
        </table>
        
        <div class="next-steps">
            <h3>Next Steps</h3>
"@
    
    if ($PhaseResult.Status -eq "Blocked") {
        $html += "<p><strong>⚠ This phase is blocked. You must resolve the critical issues above before proceeding to Phase $($Phase.Number + 1).</strong></p>"
    }
    elseif ($PhaseResult.Status -eq "Warning") {
        $html += "<p>This phase completed with warnings. Review the failed checks and decide if you want to proceed to Phase $($Phase.Number + 1).</p>"
    }
    else {
        $html += "<p>✓ Phase $($Phase.Number) complete! You can now proceed to Phase $($Phase.Number + 1): $($phases[$Phase.Number].Name)</p>"
    }
    
    $html += @"
        </div>
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-Host "  📄 Phase report saved: $reportPath" -ForegroundColor Cyan
    
    return $reportPath
}

#endregion

#region Main Execution

Show-DeploymentBanner

# Initialize session (connect to Graph and Power Platform with full user context)
$sessionInfo = Initialize-DeploymentSession

# Store user context for later use
$script:CurrentUserContext = $sessionInfo.UserContext
$script:CurrentPermissions = $sessionInfo.Permissions

# Handle reset progress
if ($ResetProgress) {
    Clear-DeploymentProgress
    Start-Sleep -Seconds 1
}

# Load progress
$progress = Get-DeploymentProgress

# Get environment and tenant info
$environmentId = $null
$tenantId = $sessionInfo.UserContext.TenantId

if ($progress) {
    $environmentId = $progress.EnvironmentId
    if ($progress.TenantId) {
        $tenantId = $progress.TenantId
    }
}

# Show phase menu
$phaseResults = @{}

if ($progress -and $progress.PhaseResults) {
    $phaseResults = $progress.PhaseResults
}

do {
    $selection = Show-PhaseMenu -Phases $phases -Progress $progress
    
    if ($selection -eq 'Q') {
        Write-Host "`nExiting deployment wizard..." -ForegroundColor Yellow
        exit 0
    }
    
    if ($selection -eq 'R') {
        Clear-DeploymentProgress
        $progress = $null
        $phaseResults = @{}
        continue
    }
    
    if ($selection -eq 'A' -or [string]::IsNullOrWhiteSpace($selection)) {
        # Run all phases or continue from current
        $startPhase = if ($progress) { $progress.CurrentPhase } else { 1 }
        
        for ($i = $startPhase; $i -le 6; $i++) {
            $phase = $phases[$i - 1]
            
            $result = Invoke-PhaseValidation -Phase $phase -EnvironmentId $environmentId
            $phaseResults."Phase$i" = $result
            
            # Save progress
            Save-DeploymentProgress -CurrentPhase $i -PhaseResults $phaseResults -EnvironmentId $environmentId -TenantId $tenantId
            
            # Generate phase report
            $reportPath = Show-PhaseReport -PhaseResult $result -Phase $phase
            
            Write-Host ""
            
            if ($result.Status -eq "Blocked") {
                Write-Host "🔒 Cannot proceed to next phase. Fix blocking issues and re-run Phase $i." -ForegroundColor Red
                break
            }
            
            if ($i -lt 6) {
                Write-Host "Press any key to continue to Phase $($i + 1)..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
        
        if ($i -eq 7) {
            Write-Host ""
            Write-Host "🎉 DEPLOYMENT COMPLETE! All 6 phases validated successfully!" -ForegroundColor Green
            Write-Host ""
        }
        
        break
    }
    
    if ($selection -match '^\d$' -and [int]$selection -ge 1 -and [int]$selection -le 6) {
        $phaseNum = [int]$selection
        $phase = $phases[$phaseNum - 1]
        
        $result = Invoke-PhaseValidation -Phase $phase -EnvironmentId $environmentId
        $phaseResults."Phase$phaseNum" = $result
        
        Save-DeploymentProgress -CurrentPhase $phaseNum -PhaseResults $phaseResults -EnvironmentId $environmentId -TenantId $tenantId
        
        $reportPath = Show-PhaseReport -PhaseResult $result -Phase $phase
        
        Write-Host ""
        Write-Host "Press any key to return to menu..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    
} while ($true)

Write-Host ""
Write-Host "Thank you for using ESS Phased Deployment Wizard!" -ForegroundColor Cyan
Write-Host ""

#endregion

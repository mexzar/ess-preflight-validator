<#
.SYNOPSIS
    ESS Pre-Flight Validator - Session Mode
    
.DESCRIPTION
    Full-featured validation session running in PowerShell 7.
    Modules load once at startup, then menu stays open for multiple tests.
    
.NOTES
    Version: 1.7.0
    Author: ESS Deployment Team
#>

#Requires -Version 7.0

param(
    [string]$ScriptRoot
)

$ErrorActionPreference = "Continue"
$WarningPreference = "SilentlyContinue"
$script:Version = "1.7.0"
$script:ScriptRoot = $ScriptRoot
$script:ModulesLoaded = $false

#region Startup and Module Loading

function Show-LoadingScreen {
    Clear-Host
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host "                                                              " -ForegroundColor Cyan
    Write-Host "         ESS PRE-FLIGHT VALIDATOR v$script:Version                " -ForegroundColor Cyan
    Write-Host "         Preparing your deployment for liftoff                " -ForegroundColor Cyan
    Write-Host "                                                              " -ForegroundColor Cyan
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Started: $(Get-Date -Format 'h:mm:ss tt')" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Yellow
    Write-Host "  LOADING - Please wait..." -ForegroundColor Yellow
    Write-Host "  ============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  This typically takes 5-10 minutes on first run." -ForegroundColor White
    Write-Host "  Once loaded, all tests will run instantly!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  The screen may appear frozen - this is NORMAL." -ForegroundColor DarkGray
    Write-Host ""
}

function Initialize-Modules {
    Write-Host "  [1/4] Loading ESS Validator module..." -ForegroundColor Gray
    $modulePath = Join-Path $script:ScriptRoot "PowerShell\ESS-Validator.psm1"
    if (Test-Path $modulePath) {
        try {
            Import-Module $modulePath -Force -ErrorAction Stop -WarningAction SilentlyContinue
            Write-Host "        OK" -ForegroundColor Green
        } catch {
            Write-Host "        Warning: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "        Not found (non-critical)" -ForegroundColor Yellow
    }
    
    Write-Host "  [2/4] Loading Microsoft Graph..." -ForegroundColor Gray
    try {
        Import-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        Write-Host "        OK" -ForegroundColor Green
    } catch {
        Write-Host "        Not available" -ForegroundColor Yellow
    }
    
    Write-Host "  [3/4] Loading Power Platform modules..." -ForegroundColor Gray
    try {
        Import-Module Microsoft.PowerApps.Administration.PowerShell -ErrorAction Stop -WarningAction SilentlyContinue
        Write-Host "        OK" -ForegroundColor Green
    } catch {
        Write-Host "        Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "  [4/4] Loading Power Platform Auth..." -ForegroundColor Gray
    try {
        # This triggers the authentication if needed
        $null = Get-AdminPowerAppEnvironment -Top 1 -ErrorAction Stop 2>$null
        Write-Host "        OK - Authenticated" -ForegroundColor Green
    } catch {
        Write-Host "        Will authenticate when running tests" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Green
    Write-Host "  READY! Modules loaded at $(Get-Date -Format 'h:mm:ss tt')" -ForegroundColor Green
    Write-Host "  ============================================================" -ForegroundColor Green
    Write-Host ""
    $script:ModulesLoaded = $true
    Start-Sleep -Seconds 2
}

#endregion

#region Banner and Menu

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host "                                                              " -ForegroundColor Cyan
    Write-Host "         ESS PRE-FLIGHT VALIDATOR v$script:Version                " -ForegroundColor Cyan
    Write-Host "         Session Mode - Modules Loaded                        " -ForegroundColor Green
    Write-Host "                                                              " -ForegroundColor Cyan
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Menu {
    Write-Host "  ------------------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "  MISSION CONTROL - What would you like to do?" -ForegroundColor Cyan
    Write-Host "  ------------------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  ACCOUNT" -ForegroundColor DarkYellow
    Write-Host "  [0] Sign In               - Connect to your Microsoft account" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  RUN ESS VALIDATION TESTS" -ForegroundColor DarkCyan
    Write-Host "  [1] Full Validation       - Complete ESS check, HTML report" -ForegroundColor White
    Write-Host "  [2] Workday Deep Dive     - Workday connections, flows, API" -ForegroundColor White
    Write-Host "  [3] ServiceNow Validation - HRSD/ITSM flows check" -ForegroundColor White
    Write-Host ""
    Write-Host "  DEPLOYMENT GUIDANCE" -ForegroundColor DarkGreen
    Write-Host "  [4] Deployment Wizard     - Guided 6-phase checklist" -ForegroundColor Green
    Write-Host ""
    Write-Host "  HELP & INFO" -ForegroundColor DarkGray
    Write-Host "  [5] Help                  - How to use this tool" -ForegroundColor Gray
    Write-Host "  [9] Am I Ready?           - Check if you can run tests" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [Q] Quit" -ForegroundColor DarkGray
    Write-Host ""
}

#endregion

#region Sign In

function Invoke-SignIn {
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Yellow
    Write-Host "  SIGN IN" -ForegroundColor Yellow
    Write-Host "  ============================================================" -ForegroundColor Yellow
    Write-Host ""
    
    # Check current connections
    Write-Host "  Checking current connections..." -ForegroundColor Gray
    Write-Host ""
    
    $graphConnected = $false
    $ppConnected = $false
    
    $graphContext = Get-MgContext -ErrorAction SilentlyContinue
    if ($graphContext) {
        Write-Host "  Microsoft Graph: " -NoNewline -ForegroundColor White
        Write-Host "$($graphContext.Account)" -ForegroundColor Green
        $graphConnected = $true
    } else {
        Write-Host "  Microsoft Graph: " -NoNewline -ForegroundColor White
        Write-Host "Not connected" -ForegroundColor Gray
    }
    
    try {
        $null = Get-AdminPowerAppEnvironment -Top 1 -ErrorAction Stop 2>$null
        Write-Host "  Power Platform:  " -NoNewline -ForegroundColor White
        Write-Host "Connected" -ForegroundColor Green
        $ppConnected = $true
    } catch {
        Write-Host "  Power Platform:  " -NoNewline -ForegroundColor White
        Write-Host "Not connected" -ForegroundColor Gray
    }
    
    Write-Host ""
    
    # If both connected, offer to switch
    if ($graphConnected -and $ppConnected) {
        Write-Host "  You're already signed in!" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Would you like to switch accounts? [y/N]: " -NoNewline -ForegroundColor Cyan
        $switch = Read-Host
        
        if ($switch -match '^[Yy]') {
            Write-Host ""
            Write-Host "  Signing out..." -ForegroundColor Gray
            try { Disconnect-MgGraph -ErrorAction SilentlyContinue } catch { }
            $graphConnected = $false
            $ppConnected = $false
        } else {
            return
        }
    }
    
    # Sign in to what's needed
    if (-not $ppConnected) {
        Write-Host "  Signing in to Power Platform..." -ForegroundColor Gray
        Write-Host "  (You may see a browser window or login prompt)" -ForegroundColor DarkGray
        Write-Host ""
        try {
            Add-PowerAppsAccount -ErrorAction Stop
            Write-Host "  [OK] Connected to Power Platform" -ForegroundColor Green
        } catch {
            Write-Host "  [X] Power Platform sign-in failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    
    if (-not $graphConnected) {
        Write-Host "  Signing in to Microsoft Graph..." -ForegroundColor Gray
        Write-Host "  (Browser window will open)" -ForegroundColor DarkGray
        Write-Host ""
        try {
            Connect-MgGraph -Scopes "User.Read.All","Organization.Read.All" -ErrorAction Stop
            $ctx = Get-MgContext
            Write-Host "  [OK] Connected as $($ctx.Account)" -ForegroundColor Green
        } catch {
            Write-Host "  [X] Graph sign-in failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Green
    Write-Host "  Sign-in complete! You can now run tests." -ForegroundColor Green
    Write-Host "  ============================================================" -ForegroundColor Green
}

#endregion

#region Full Validation

function Invoke-FullValidation {
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host "  FULL ESS VALIDATION" -ForegroundColor Cyan
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $scriptPath = Join-Path $script:ScriptRoot "PowerShell\Start-ESSValidation.ps1"
    if (-not (Test-Path $scriptPath)) {
        Write-Host "  [X] Start-ESSValidation.ps1 not found" -ForegroundColor Red
        return
    }
    
    & $scriptPath
}

#endregion

#region Workday Validation

function Show-WorkdayMenu {
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Magenta
    Write-Host "  WORKDAY DEEP DIVE" -ForegroundColor Magenta
    Write-Host "  ============================================================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  Which Workday test would you like to run?" -ForegroundColor White
    Write-Host ""
    Write-Host "  POWER PLATFORM CHECKS" -ForegroundColor DarkGray
    Write-Host "  [A] Run All Tests         - Complete validation (1-3 below)" -ForegroundColor White
    Write-Host "  [1] Connection References - Are Workday connectors authenticated?" -ForegroundColor White
    Write-Host "  [2] Environment Variables - RaaS account name configured?" -ForegroundColor White
    Write-Host "  [3] Flow Status           - Are Workday flows turned on?" -ForegroundColor White
    Write-Host "  [4] SSO Configuration     - Security domain checklist (Admin)" -ForegroundColor White
    Write-Host ""
    Write-Host "  WORKDAY API TESTS" -ForegroundColor DarkGray
    Write-Host "  [5] Basic User Test       - Test Workday API with credentials" -ForegroundColor White
    Write-Host "  [6] SSO Connectivity      - Test Azure AD OAuth flow (end-user)" -ForegroundColor White
    Write-Host ""
    Write-Host "  [B] Back to main menu" -ForegroundColor DarkGray
    Write-Host ""
}

function Invoke-WorkdayValidation {
    while ($true) {
        Show-WorkdayMenu
        Write-Host "  Select option: " -NoNewline -ForegroundColor Cyan
        $choice = Read-Host
        
        if ($choice -match '^[Bb]$') { return }
        
        $workdaySuitePath = Join-Path $script:ScriptRoot "PowerShell\WorkdaySuite"
        
        switch ($choice.ToUpper()) {
            "A" {
                Write-Host ""
                Write-Host "  Enter Power Platform Environment ID: " -NoNewline -ForegroundColor Cyan
                $envId = Read-Host
                if ([string]::IsNullOrWhiteSpace($envId)) {
                    Write-Host "  [X] Environment ID required" -ForegroundColor Red
                } else {
                    $script = Join-Path $workdaySuitePath "Invoke-WorkdayValidationSuite.ps1"
                    & $script -EnvironmentId $envId -SkipConnectivityTest
                }
            }
            "1" {
                Write-Host ""
                Write-Host "  Enter Power Platform Environment ID: " -NoNewline -ForegroundColor Cyan
                $envId = Read-Host
                if ([string]::IsNullOrWhiteSpace($envId)) {
                    Write-Host "  [X] Environment ID required" -ForegroundColor Red
                } else {
                    . (Join-Path $workdaySuitePath "Test-WorkdayConnectionReferences.ps1")
                    $results = Test-WorkdayConnectionReferences -EnvironmentId $envId
                    Show-ResultsSummary $results
                }
            }
            "2" {
                Write-Host ""
                Write-Host "  Enter Power Platform Environment ID: " -NoNewline -ForegroundColor Cyan
                $envId = Read-Host
                if ([string]::IsNullOrWhiteSpace($envId)) {
                    Write-Host "  [X] Environment ID required" -ForegroundColor Red
                } else {
                    . (Join-Path $workdaySuitePath "Test-WorkdayEnvironmentVariables.ps1")
                    $results = Test-WorkdayEnvironmentVariables -EnvironmentId $envId
                    Show-ResultsSummary $results
                }
            }
            "3" {
                Write-Host ""
                Write-Host "  Enter Power Platform Environment ID: " -NoNewline -ForegroundColor Cyan
                $envId = Read-Host
                if ([string]::IsNullOrWhiteSpace($envId)) {
                    Write-Host "  [X] Environment ID required" -ForegroundColor Red
                } else {
                    . (Join-Path $workdaySuitePath "Test-WorkdayFlowStatus.ps1")
                    $results = Test-WorkdayFlowStatus -EnvironmentId $envId
                    Show-ResultsSummary $results
                }
            }
            "4" {
                Write-Host ""
                Write-Host "  Enter Power Platform Environment ID: " -NoNewline -ForegroundColor Cyan
                $envId = Read-Host
                if ([string]::IsNullOrWhiteSpace($envId)) {
                    Write-Host "  [X] Environment ID required" -ForegroundColor Red
                } else {
                    . (Join-Path $workdaySuitePath "Test-WorkdaySSOConfiguration.ps1")
                    Test-WorkdaySSOConfiguration -EnvironmentId $envId
                }
            }
            "5" {
                $script = Join-Path $script:ScriptRoot "PowerShell\Test-WorkdayConnectivity.ps1"
                if (Test-Path $script) {
                    & $script
                } else {
                    Write-Host "  [X] Test-WorkdayConnectivity.ps1 not found" -ForegroundColor Red
                }
            }
            "6" {
                $script = Join-Path $script:ScriptRoot "PowerShell\Test-WorkdaySSOConnectivity.ps1"
                if (Test-Path $script) {
                    & $script
                } else {
                    Write-Host "  [X] Test-WorkdaySSOConnectivity.ps1 not found" -ForegroundColor Red
                }
            }
            default {
                Write-Host "  [X] Invalid option" -ForegroundColor Red
            }
        }
        
        Write-Host ""
        Write-Host "  Press any key to continue..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}

function Show-ResultsSummary {
    param($results)
    
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host "  RESULTS SUMMARY" -ForegroundColor Cyan
    Write-Host "  ============================================================" -ForegroundColor Cyan
    
    $passed = ($results | Where-Object { $_.Status -eq 'Passed' }).Count
    $failed = ($results | Where-Object { $_.Status -eq 'Failed' }).Count
    $warnings = ($results | Where-Object { $_.Status -eq 'Warning' }).Count
    
    Write-Host "  Passed: $passed" -ForegroundColor Green
    Write-Host "  Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { 'Red' } else { 'Green' })
    Write-Host "  Warnings: $warnings" -ForegroundColor $(if ($warnings -gt 0) { 'Yellow' } else { 'Green' })
}

#endregion

#region ServiceNow Validation

function Invoke-ServiceNowValidation {
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host "  SERVICENOW VALIDATION" -ForegroundColor Cyan
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  Enter Power Platform Environment ID: " -NoNewline -ForegroundColor Cyan
    $envId = Read-Host
    
    if ([string]::IsNullOrWhiteSpace($envId)) {
        Write-Host "  [X] Environment ID is required" -ForegroundColor Red
        return
    }
    
    Write-Host ""
    Write-Host "  Checking ServiceNow flows..." -ForegroundColor Gray
    
    try {
        $flows = Get-AdminFlow -EnvironmentName $envId -ErrorAction Stop | 
                 Where-Object { $_.DisplayName -like '*ServiceNow*' }
        
        if ($flows) {
            Write-Host ""
            Write-Host "  [OK] Found $($flows.Count) ServiceNow flow(s)" -ForegroundColor Green
            Write-Host ""
            
            # Categorize flows
            $hrsd = $flows | Where-Object { $_.DisplayName -match 'HRSD|HR Service' }
            $itsm = $flows | Where-Object { $_.DisplayName -match 'ITSM|Incident|Ticket' }
            $other = $flows | Where-Object { $_.DisplayName -notmatch 'HRSD|HR Service|ITSM|Incident|Ticket' }
            
            if ($hrsd) {
                Write-Host "  HRSD Flows ($($hrsd.Count))" -ForegroundColor Cyan
                foreach ($flow in $hrsd) {
                    $status = if ($flow.Enabled) { "ON" } else { "OFF" }
                    $color = if ($flow.Enabled) { "Green" } else { "Red" }
                    Write-Host "    [$status] $($flow.DisplayName)" -ForegroundColor $color
                }
                Write-Host ""
            }
            
            if ($itsm) {
                Write-Host "  ITSM Flows ($($itsm.Count))" -ForegroundColor Cyan
                foreach ($flow in $itsm) {
                    $status = if ($flow.Enabled) { "ON" } else { "OFF" }
                    $color = if ($flow.Enabled) { "Green" } else { "Red" }
                    Write-Host "    [$status] $($flow.DisplayName)" -ForegroundColor $color
                }
                Write-Host ""
            }
            
            if ($other) {
                Write-Host "  Other ServiceNow Flows ($($other.Count))" -ForegroundColor Cyan
                foreach ($flow in $other) {
                    $status = if ($flow.Enabled) { "ON" } else { "OFF" }
                    $color = if ($flow.Enabled) { "Green" } else { "Red" }
                    Write-Host "    [$status] $($flow.DisplayName)" -ForegroundColor $color
                }
                Write-Host ""
            }
            
            $enabledCount = ($flows | Where-Object { $_.Enabled }).Count
            $disabledCount = ($flows | Where-Object { -not $_.Enabled }).Count
            Write-Host "  Summary: $enabledCount enabled, $disabledCount disabled" -ForegroundColor $(if ($disabledCount -gt 0) { 'Yellow' } else { 'Green' })
        } else {
            Write-Host "  [i] No ServiceNow flows found in this environment" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  [X] Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

#endregion

#region Deployment Wizard

function Invoke-DeploymentWizard {
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Green
    Write-Host "  DEPLOYMENT WIZARD" -ForegroundColor Green
    Write-Host "  ============================================================" -ForegroundColor Green
    Write-Host ""
    
    $scriptPath = Join-Path $script:ScriptRoot "PowerShell\Start-ESSDeployment.ps1"
    if (Test-Path $scriptPath) {
        & $scriptPath
    } else {
        Write-Host "  [X] Start-ESSDeployment.ps1 not found" -ForegroundColor Red
    }
}

#endregion

#region Help

function Show-Help {
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor White
    Write-Host "  HELP - ESS Pre-Flight Validator" -ForegroundColor White
    Write-Host "  ============================================================" -ForegroundColor White
    Write-Host ""
    Write-Host "  PREREQUISITES" -ForegroundColor Cyan
    Write-Host "  ─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  • PowerShell 7.x         (You have it - you're running this!)" -ForegroundColor Green
    Write-Host "  • Microsoft Graph module (Install-Module Microsoft.Graph)" -ForegroundColor White
    Write-Host "  • Power Platform module  (Install-Module Microsoft.PowerApps.Administration.PowerShell)" -ForegroundColor White
    Write-Host ""
    Write-Host "  PERMISSIONS NEEDED" -ForegroundColor Cyan
    Write-Host "  ─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  • Power Platform Administrator (or Environment Admin)" -ForegroundColor White
    Write-Host "  • Microsoft 365 Global Reader (for Graph queries)" -ForegroundColor White
    Write-Host ""
    Write-Host "  FINDING YOUR ENVIRONMENT ID" -ForegroundColor Cyan
    Write-Host "  ─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  1. Go to https://admin.powerplatform.microsoft.com" -ForegroundColor White
    Write-Host "  2. Click on your environment" -ForegroundColor White
    Write-Host "  3. Copy the GUID from the URL or Environment Details" -ForegroundColor White
    Write-Host ""
    Write-Host "  QUICK START" -ForegroundColor Cyan
    Write-Host "  ─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  1. Run [1] Full Validation for complete ESS health check" -ForegroundColor White
    Write-Host "  2. Use [2] Workday Deep Dive for Workday-specific issues" -ForegroundColor White
    Write-Host "  3. Use [3] ServiceNow to check HRSD/ITSM flows" -ForegroundColor White
    Write-Host ""
    Write-Host "  SESSION MODE" -ForegroundColor Cyan
    Write-Host "  ─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  Modules are loaded once at startup. Run multiple tests" -ForegroundColor White
    Write-Host "  without waiting! Each test runs instantly after loading." -ForegroundColor Green
    Write-Host ""
}

function Show-SessionInfo {
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host "  CHECK IF YOU'RE READY TO RUN TESTS" -ForegroundColor Cyan
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $allGood = $true
    $needsSignIn = $false
    
    # Check 1: Power Platform connection
    Write-Host "  STEP 1: Power Platform Connection" -ForegroundColor White
    Write-Host "  ─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    try {
        $null = Get-AdminPowerAppEnvironment -Top 1 -ErrorAction Stop 2>$null
        Write-Host "    [OK] Connected - You can access Power Platform" -ForegroundColor Green
    } catch {
        Write-Host "    [X] Not connected" -ForegroundColor Red
        Write-Host "        Use [0] Sign In to connect" -ForegroundColor Yellow
        $allGood = $false
        $needsSignIn = $true
    }
    Write-Host ""
    
    # Check 2: Microsoft Graph (optional but helpful)
    Write-Host "  STEP 2: Microsoft Graph Connection (optional)" -ForegroundColor White
    Write-Host "  ─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    $graphContext = Get-MgContext -ErrorAction SilentlyContinue
    if ($graphContext) {
        Write-Host "    [OK] Connected as $($graphContext.Account)" -ForegroundColor Green
    } else {
        Write-Host "    [--] Not connected (some features may be limited)" -ForegroundColor Gray
        Write-Host "        Use [0] Sign In if needed" -ForegroundColor DarkGray
    }
    Write-Host ""
    
    # Check 3: Required modules
    Write-Host "  STEP 3: Required Software" -ForegroundColor White
    Write-Host "  ─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    
    $ppMod = Get-Module Microsoft.PowerApps.Administration.PowerShell -ErrorAction SilentlyContinue
    if ($ppMod) {
        Write-Host "    [OK] Power Platform tools loaded" -ForegroundColor Green
    } else {
        $available = Get-Module -ListAvailable Microsoft.PowerApps.Administration.PowerShell -ErrorAction SilentlyContinue
        if ($available) {
            Write-Host "    [OK] Power Platform tools installed" -ForegroundColor Green
        } else {
            Write-Host "    [X] Power Platform tools missing" -ForegroundColor Red
            Write-Host "        Run: Install-Module Microsoft.PowerApps.Administration.PowerShell" -ForegroundColor Yellow
            $allGood = $false
        }
    }
    Write-Host ""
    
    # Summary and next steps
    Write-Host "  ============================================================" -ForegroundColor $(if ($allGood) { 'Green' } else { 'Yellow' })
    if ($allGood) {
        Write-Host "  YOU'RE ALL SET!" -ForegroundColor Green
        Write-Host "  ============================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Go ahead and run any test from the main menu:" -ForegroundColor White
        Write-Host "    [1] Full Validation - Complete health check" -ForegroundColor Gray
        Write-Host "    [2] Workday Deep Dive - Workday-specific tests" -ForegroundColor Gray
        Write-Host "    [3] ServiceNow - Check ServiceNow flows" -ForegroundColor Gray
    } elseif ($needsSignIn) {
        Write-Host "  SIGN IN NEEDED" -ForegroundColor Yellow
        Write-Host "  ============================================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Before running tests, you need to sign in:" -ForegroundColor White
        Write-Host ""
        Write-Host "  Press [0] from the main menu to sign in" -ForegroundColor Cyan
    } else {
        Write-Host "  SETUP NEEDED" -ForegroundColor Yellow
        Write-Host "  ============================================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Please install the missing components listed above." -ForegroundColor White
    }
    Write-Host ""
}

#endregion

#region Main Loop

function Start-Session {
    # Show loading screen and initialize
    Show-LoadingScreen
    Initialize-Modules
    
    # Main menu loop
    while ($true) {
        Show-Banner
        Show-Menu
        
        Write-Host "  Select option: " -NoNewline -ForegroundColor Cyan
        $choice = Read-Host
        
        switch ($choice.ToUpper()) {
            "0" { Invoke-SignIn; Pause-ForUser }
            "1" { Invoke-FullValidation; Pause-ForUser }
            "2" { Invoke-WorkdayValidation }
            "3" { Invoke-ServiceNowValidation; Pause-ForUser }
            "4" { Invoke-DeploymentWizard; Pause-ForUser }
            "5" { Show-Help; Pause-ForUser }
            "9" { Show-SessionInfo; Pause-ForUser }
            "Q" {
                Write-Host ""
                Write-Host "  Thank you for using ESS Pre-Flight Validator!" -ForegroundColor Cyan
                Write-Host ""
                Start-Sleep -Seconds 1
                exit
            }
            default {
                Write-Host ""
                Write-Host "  [X] Invalid option. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

function Pause-ForUser {
    Write-Host ""
    Write-Host "  Press any key to return to menu..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

# Start the session
Start-Session

#endregion

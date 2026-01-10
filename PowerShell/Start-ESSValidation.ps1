<#
.SYNOPSIS
    Interactive wizard for ESS Pre-flight Deployment Validation
.DESCRIPTION
    User-friendly wizard that wraps ESS-Validator.psm1 with:
    - Auto-detection of user context
    - Profile management (save/load preferences)
    - Interactive environment and agent selection
    - Personal permission validation
    - Progress tracking with visual feedback
    - Automatic report generation and opening
    - Advanced filtering options for focused validation
.PARAMETER SkipProfile
    Skip loading saved profiles and start fresh
.PARAMETER NoOpenReport
    Don't automatically open the HTML report after validation
.PARAMETER ShowFailedOnly
    Only show failed validation checks in the report
.PARAMETER ShowCriticalOnly
    Only show critical/high-priority validation checks
.PARAMETER Categories
    Filter by specific categories (comma-separated): Prerequisites,Environment,Authentication,ExternalSystems,Content,Topics,Configuration,Publishing,Deployment
.PARAMETER Priority
    Filter by priority level: Critical, High, Medium, Low
.EXAMPLE
    .\Start-ESSValidation.ps1
    Launches interactive wizard with saved profile detection
.EXAMPLE
    .\Start-ESSValidation.ps1 -SkipProfile
    Launches wizard without loading saved profiles
.EXAMPLE
    .\Start-ESSValidation.ps1 -ShowFailedOnly
    Run validation and only show failed checks in the report
.EXAMPLE
    .\Start-ESSValidation.ps1 -Categories "Prerequisites,Authentication" -Priority "Critical"
    Run only critical prerequisites and authentication checks
.NOTES
    Requires: ESS-Validator.psm1 module
    Author: ESS Pre-flight Validator
    Version: 2.0.0
#>

[CmdletBinding()]
param(
    [switch]$SkipProfile,
    [switch]$NoOpenReport,
    [switch]$ShowFailedOnly,
    [switch]$ShowCriticalOnly,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Prerequisites", "Environment", "Authentication", "ExternalSystems", "Content", "Topics", "Configuration", "Publishing", "Deployment")]
    [string[]]$Categories,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Critical", "High", "Medium", "Low")]
    [string]$Priority
)

#Requires -Version 7.0

Write-Host "Loading ESS Validation Wizard..." -ForegroundColor Cyan

# Import the ESS-Validator module
$modulePath = Join-Path $PSScriptRoot "ESS-Validator.psm1"
if (-not (Test-Path $modulePath)) {
    Write-Host "❌ Error: ESS-Validator.psm1 not found at: $modulePath" -ForegroundColor Red
    Write-Host "   Please ensure ESS-Validator.psm1 is in the same directory as this script." -ForegroundColor Yellow
    exit 1
}

Write-Host "  • Loading validation module..." -ForegroundColor Gray
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Write-Host "  • Loading Microsoft Graph..." -ForegroundColor Gray
# Only import if not already loaded (speeds up subsequent runs)
if (-not (Get-Module Microsoft.Graph.Identity.DirectoryManagement)) {
    Import-Module Microsoft.Graph.Identity.DirectoryManagement -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
}
if (-not (Get-Module Microsoft.Graph.Users)) {
    Import-Module Microsoft.Graph.Users -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
}

Write-Host "  • Loading Power Platform..." -ForegroundColor Gray
# Only import if not already loaded
if (-not (Get-Module Microsoft.PowerApps.Administration.PowerShell)) {
    Import-Module Microsoft.PowerApps.Administration.PowerShell -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
}

Write-Host "✓ Ready!" -ForegroundColor Green

# Profile storage location
$profileDir = Join-Path $HOME ".ess-validator"
$profilePath = Join-Path $profileDir "profiles.json"

#region Helper Functions

function Show-Banner {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     ESS Pre-flight Deployment Validation Wizard v1.0           ║" -ForegroundColor Cyan
    Write-Host "║     Interactive validation for Employee Self-Service           ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
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

function Save-ValidationProfile {
    param(
        [hashtable]$Profile
    )
    
    try {
        if (-not (Test-Path $profileDir)) {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }
        
        $profiles = @()
        if (Test-Path $profilePath) {
            $existingProfiles = Get-Content $profilePath -Raw | ConvertFrom-Json
            # Convert from PSCustomObject array to array if needed
            if ($existingProfiles) {
                $profiles = @($existingProfiles)
            }
        }
        
        # Add timestamp
        $Profile.LastUsed = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        
        # Remove old profile with same name
        $profiles = @($profiles | Where-Object { $_.Name -ne $Profile.Name })
        
        # Add new profile as PSCustomObject to match JSON structure
        $profiles += [PSCustomObject]$Profile
        
        # Keep only last 5 profiles
        $profiles = @($profiles | Sort-Object LastUsed -Descending | Select-Object -First 5)
        
        $profiles | ConvertTo-Json -Depth 10 | Set-Content $profilePath
        
        Write-Host "✓ Profile saved: $($Profile.Name)" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️  Could not save profile: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Get-SavedProfiles {
    try {
        if (Test-Path $profilePath) {
            return Get-Content $profilePath -Raw | ConvertFrom-Json
        }
    }
    catch {
        Write-Host "⚠️  Could not load profiles: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    return @()
}

function Select-Environment {
    param(
        [string]$TenantId,
        [switch]$ForceReconnect
    )
    
    Write-Host ""
    Write-Host "🌍 Loading Power Platform environments..." -ForegroundColor Cyan
    
    try {
        # Check if we need to connect/reconnect to Power Platform
        $needsConnection = $false
        
        if ($ForceReconnect) {
            Write-Host "  Reconnecting to Power Platform with new account..." -ForegroundColor Gray
            $needsConnection = $true
        } else {
            $ppContext = Get-AdminPowerAppEnvironment -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $ppContext) {
                Write-Host "  Connecting to Power Platform..." -ForegroundColor Gray
                $needsConnection = $true
            }
        }
        
        if ($needsConnection) {
            if ($TenantId) {
                Add-PowerAppsAccount -TenantID $TenantId | Out-Null
            } else {
                Add-PowerAppsAccount | Out-Null
            }
        }
        
        $environments = Get-AdminPowerAppEnvironment | Where-Object { $_.Internal.properties.linkedEnvironmentMetadata.type -ne 'NotSpecified' }
        
        if ($environments.Count -eq 0) {
            Write-Host "❌ No Power Platform environments found" -ForegroundColor Red
            return $null
        }
        
        Write-Host "✓ Found $($environments.Count) environment(s)" -ForegroundColor Green
        Write-Host ""
        
        # Check if user wants to search for specific environment
        Write-Host "💡 Tip: You can search in the grid by typing in the search box" -ForegroundColor Cyan
        $searchFirst = Get-UserConfirmation "Do you know the environment name/ID to search for?" $false
        
        if ($searchFirst) {
            $searchTerm = Read-Host "Enter environment name or ID to search"
            if (-not [string]::IsNullOrWhiteSpace($searchTerm)) {
                $filtered = $environments | Where-Object { 
                    $_.DisplayName -like "*$searchTerm*" -or 
                    $_.EnvironmentName -like "*$searchTerm*" 
                }
                
                if ($filtered.Count -gt 0) {
                    Write-Host "✓ Found $($filtered.Count) matching environment(s)" -ForegroundColor Green
                    $environments = $filtered
                }
                else {
                    Write-Host "⚠️  No matches found. Showing all environments." -ForegroundColor Yellow
                }
            }
        }
        
        # Show environment picker with more details
        $env = $environments | 
            Select-Object DisplayName, EnvironmentName, @{Name='Type';Expression={$_.EnvironmentType}}, @{Name='Region';Expression={$_.Location}} |
            Sort-Object DisplayName |
            Out-GridView -Title "Select Power Platform Environment for ESS Validation ($($environments.Count) environments)" -OutputMode Single
        
        if ($env) {
            # Get the full environment object back
            $selectedEnv = $environments | Where-Object { $_.EnvironmentName -eq $env.EnvironmentName }
            Write-Host "✓ Selected: " -NoNewline -ForegroundColor Green
            Write-Host "$($selectedEnv.DisplayName) " -NoNewline
            Write-Host "($($selectedEnv.EnvironmentName))" -ForegroundColor DarkGray
            return $selectedEnv
        }
        
        return $null
    }
    catch {
        Write-Host "❌ Error loading environments: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Get-AgentName {
    param(
        [string]$DefaultName = "Employee Self-Service IT (Preview)Sandbox"
    )
    
    Write-Host ""
    Write-Host "🤖 ESS Agent Configuration" -ForegroundColor Cyan
    Write-Host "   Default agent name: " -NoNewline
    Write-Host $DefaultName -ForegroundColor Yellow
    Write-Host ""
    
    $useDefault = Get-UserConfirmation "Use this agent name?" $true
    
    if ($useDefault) {
        return $DefaultName
    }
    
    $customName = Read-Host "Enter custom agent name"
    
    if ([string]::IsNullOrWhiteSpace($customName)) {
        return $DefaultName
    }
    
    return $customName
}

function Show-ProgressBar {
    param(
        [int]$Percent,
        [string]$Status
    )
    
    $barLength = 50
    $filled = [math]::Floor($barLength * $Percent / 100)
    $empty = $barLength - $filled
    
    $bar = "█" * $filled + "░" * $empty
    
    Write-Host "`r[$bar] $Percent% - $Status" -NoNewline
}

#endregion

#region Main Wizard Flow

try {
    Show-Banner
    
    # Step 1: Detect current user
    $userContext = Get-CurrentUserContext
    
    if ($userContext.UserPrincipalName) {
        Write-Host "✓ Detected user: " -NoNewline -ForegroundColor Green
        Write-Host $userContext.UserPrincipalName
    }
    
    # Allow user to override detected account
    Write-Host ""
    $useDetected = Get-UserConfirmation "Use this account for validation?" $true
    
    $accountSwitched = $false
    if (-not $useDetected) {
        $customAccount = Read-Host "Enter account to use (e.g., admin@YourESSDoamin.com)"
        
        if (-not [string]::IsNullOrWhiteSpace($customAccount)) {
            Write-Host "✓ Using account: " -NoNewline -ForegroundColor Green
            Write-Host $customAccount
            
            # Disconnect current sessions
            try {
                Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
            } catch {}
            
            # Force new connection with specified account
            Write-Host "🔐 Connecting to Microsoft Graph as $customAccount..." -ForegroundColor Cyan
            Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All", "RoleManagement.Read.All", "Organization.Read.All" -NoWelcome
            
            # Update user context
            $newContext = Get-MgContext
            $userContext.UserPrincipalName = $newContext.Account
            $userContext.TenantId = $newContext.TenantId
            $userContext.Connected = $true
            $accountSwitched = $true
        }
    }
    
    Write-Host ""
    
    # Step 2: Check for saved profiles
    $savedProfile = $null
    
    if (-not $SkipProfile) {
        $profiles = Get-SavedProfiles
        
        if ($profiles -and $profiles.Count -gt 0) {
            $lastProfile = $profiles | Sort-Object LastUsed -Descending | Select-Object -First 1
            
            Write-Host "✓ Found saved profile: " -NoNewline -ForegroundColor Green
            Write-Host "'$($lastProfile.Name)' " -NoNewline -ForegroundColor Yellow
            Write-Host "(last used $($lastProfile.LastUsed))" -ForegroundColor DarkGray
            Write-Host ""
            
            $useProfile = Get-UserConfirmation "Use saved profile?" $true
            
            if ($useProfile) {
                $savedProfile = $lastProfile
                Write-Host ""
                Write-Host "✓ Tenant: " -NoNewline -ForegroundColor Green
                Write-Host "$($savedProfile.TenantName) " -NoNewline
                Write-Host "($($savedProfile.TenantId.Substring(0,8))...)" -ForegroundColor DarkGray
                
                Write-Host "✓ Environment: " -NoNewline -ForegroundColor Green
                Write-Host $savedProfile.EnvironmentName
                
                Write-Host "✓ Agent: " -NoNewline -ForegroundColor Green
                Write-Host $savedProfile.AgentName
                Write-Host ""
            }
        }
    }
    
    # Step 3: If no saved profile, gather information
    $tenantId = $null
    $tenantName = $null
    $environment = $null
    $agentName = $null
    
    if ($savedProfile) {
        # Use saved profile values
        $tenantId = $savedProfile.TenantId
        $tenantName = $savedProfile.TenantName
        $agentName = $savedProfile.AgentName
        
        # Load environment from saved profile
        try {
            $environment = Get-AdminPowerAppEnvironment -EnvironmentName $savedProfile.EnvironmentId -ErrorAction Stop
        }
        catch {
            Write-Host "⚠️  Saved environment not found. Please select a new environment." -ForegroundColor Yellow
            $environment = Select-Environment -TenantId $tenantId
            
            if (-not $environment) {
                Write-Host "❌ Environment selection is required. Exiting." -ForegroundColor Red
                exit 1
            }
        }
    }
    else {
        # Get Tenant ID
        if ($userContext.TenantId) {
            $tenantId = $userContext.TenantId
            Write-Host "✓ Using current tenant: " -NoNewline -ForegroundColor Green
            Write-Host "$tenantId"
        } else {
            Write-Host ""
            $tenantId = Read-Host "Enter Tenant ID (or press Enter to skip)"
            if ([string]::IsNullOrWhiteSpace($tenantId)) {
                Write-Host "  ℹ  No tenant ID provided - will use interactive authentication" -ForegroundColor Cyan
                $tenantId = $null
            }
        }
        
        # Select Environment
        if ($accountSwitched) {
            $environment = Select-Environment -TenantId $tenantId -ForceReconnect
        } else {
            $environment = Select-Environment -TenantId $tenantId
        }
        
        if (-not $environment) {
            Write-Host "❌ Environment selection is required. Exiting." -ForegroundColor Red
            exit 1
        }
        
        # Get Agent Name
        $agentName = Get-AgentName
        
        # Get tenant name for profile
        try {
            $org = Get-MgOrganization -ErrorAction SilentlyContinue | Select-Object -First 1
            $tenantName = $org.DisplayName
        }
        catch {
            $tenantName = "Unknown"
        }
    }
    
    # Step 4: Check personal permissions
    $permissions = Test-MyPermissions -TenantId $tenantId
    
    # Step 5: Confirm validation run
    $runValidation = Get-UserConfirmation "Run full validation?" $true
    
    if (-not $runValidation) {
        Write-Host ""
        Write-Host "Validation cancelled by user." -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Starting Validation..." -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # Step 6: Run validation with progress indicators
    $reportDir = Join-Path ([Environment]::GetFolderPath("Desktop")) "ESS-Reports"
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $reportPath = Join-Path $reportDir "ESS-Validation-$timestamp.html"
    
    Show-ProgressBar -Percent 10 -Status "Testing prerequisites..."
    $prereqResults = Test-ESSPrerequisites
    
    Show-ProgressBar -Percent 30 -Status "Validating environment..."
    $envResults = Test-ESSEnvironment -EnvironmentId $environment.EnvironmentName
    
    Show-ProgressBar -Percent 50 -Status "Checking authentication..."
    $authResults = Test-ESSAuthentication
    
    Show-ProgressBar -Percent 70 -Status "Validating external systems..."
    $extResults = Test-ESSExternalSystems -EnvironmentId $environment.EnvironmentName
    
    Show-ProgressBar -Percent 90 -Status "Generating comprehensive report..."
    
    # Run full validation and generate report
    $fullResults = Test-ESSDeploymentReadiness -Scope Full -EnvironmentId $environment.EnvironmentName -OutputFormat HTML -ExportPath $reportPath
    
    # Apply filtering if specified
    $filteredResults = $fullResults
    $filterApplied = $false
    
    if ($ShowFailedOnly) {
        Write-Host "  🔍 Applying filter: Show failed checks only" -ForegroundColor Yellow
        $filteredResults = $filteredResults | Where-Object { $_.Status -eq 'Failed' }
        $filterApplied = $true
    }
    
    if ($ShowCriticalOnly) {
        Write-Host "  🔍 Applying filter: Show critical checks only" -ForegroundColor Yellow
        $filteredResults = $filteredResults | Where-Object { $_.Priority -eq 'Critical' -or $_.Priority -eq 'High' }
        $filterApplied = $true
    }
    
    if ($Categories) {
        Write-Host "  🔍 Applying filter: Categories = $($Categories -join ', ')" -ForegroundColor Yellow
        $filteredResults = $filteredResults | Where-Object { $_.Category -in $Categories }
        $filterApplied = $true
    }
    
    if ($Priority) {
        Write-Host "  🔍 Applying filter: Priority = $Priority" -ForegroundColor Yellow
        $filteredResults = $filteredResults | Where-Object { $_.Priority -eq $Priority }
        $filterApplied = $true
    }
    
    if ($filterApplied) {
        Write-Host "  📊 Filtered results: $($filteredResults.Count) of $($fullResults.Count) checks" -ForegroundColor Cyan
    }
    
    Show-ProgressBar -Percent 100 -Status "Complete!"
    Write-Host ""
    Write-Host ""
    
    # Step 7: Display summary
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Validation Complete!" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # Count results from filtered data
    $dataToDisplay = if ($filterApplied) { $filteredResults } else { $fullResults }
    
    $passed = ($dataToDisplay | Where-Object { $_.Status -eq 'Passed' }).Count
    $failed = ($dataToDisplay | Where-Object { $_.Status -eq 'Failed' }).Count
    $warnings = ($dataToDisplay | Where-Object { $_.Status -eq 'Warning' }).Count
    $notConfigured = ($dataToDisplay | Where-Object { $_.Status -eq 'NotConfigured' }).Count
    
    if ($filterApplied) {
        Write-Host "  Showing Filtered Results:" -ForegroundColor Yellow
        Write-Host "  Total Checks (filtered): " -NoNewline
    }
    else {
        Write-Host "  Total Checks: " -NoNewline
    }
    Write-Host $dataToDisplay.Count
    
    Write-Host "  ✓ Passed: " -NoNewline -ForegroundColor Green
    Write-Host $passed
    
    if ($failed -gt 0) {
        Write-Host "  ✗ Failed: " -NoNewline -ForegroundColor Red
        Write-Host $failed
    }
    
    if ($warnings -gt 0) {
        Write-Host "  ⚠  Warnings: " -NoNewline -ForegroundColor Yellow
        Write-Host $warnings
    }
    
    Write-Host "  ○ Not Configured: " -NoNewline -ForegroundColor Gray
    Write-Host $notConfigured
    
    Write-Host ""
    
    # Show critical issues
    $criticalIssues = $fullResults | Where-Object { $_.Status -eq 'Failed' -and $_.Priority -eq 'Critical' }
    
    if ($criticalIssues) {
        Write-Host "🚨 Critical Issues Found:" -ForegroundColor Red
        foreach ($issue in $criticalIssues) {
            Write-Host "   • $($issue.CheckpointId): " -NoNewline -ForegroundColor Red
            Write-Host $issue.Result
        }
        Write-Host ""
    }
    
    Write-Host "📄 Report saved: " -NoNewline
    Write-Host $reportPath -ForegroundColor Yellow
    Write-Host ""
    
    # Step 8: Save profile for next time
    if (-not $savedProfile -or $savedProfile.EnvironmentId -ne $environment.EnvironmentName) {
        $profileName = "$($environment.DisplayName) - $(Get-Date -Format 'yyyy-MM-dd')"
        
        $newProfile = @{
            Name = $profileName
            TenantId = if ($tenantId) { $tenantId } else { (Get-MgContext).TenantId }
            TenantName = $tenantName
            EnvironmentId = $environment.EnvironmentName
            EnvironmentName = $environment.DisplayName
            AgentName = $agentName
        }
        
        Save-ValidationProfile -Profile $newProfile
        Write-Host ""
    }
    
    # Step 9: Open report
    if (-not $NoOpenReport) {
        $openReport = Get-UserConfirmation "Open report in browser?" $true
        
        if ($openReport) {
            Start-Process $reportPath
        }
    }
    
    Write-Host ""
    Write-Host "Thank you for using ESS Pre-flight Validator! 🚀" -ForegroundColor Cyan
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Stack trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    exit 1
}

#endregion

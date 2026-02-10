<#
.SYNOPSIS
    Validates Workday SSO configuration for ESS Agent integration.

.DESCRIPTION
    Deep diagnostic tool for Workday Single Sign-On (SSO) configuration.
    Validates the 4 required connections, identifies auth types, and
    generates a security domain checklist for Workday administrators.

.PARAMETER EnvironmentId
    The Power Platform environment ID to validate.

.PARAMETER OAuthUserConnection
    Name of the OAuthUser connection (for employee SSO queries).

.PARAMETER ISUWQLConnection
    Name of the ISU_WQL connection (for user context lookup).

.PARAMETER ISUGenericConnection
    Name of the ISU_Generic connection (for template retrieval).

.PARAMETER DataverseConnection
    Name of the Dataverse connection (for ESS templates).

.PARAMETER GenerateChecklist
    Exports a Workday Admin checklist to a text file.

.PARAMETER SkipPrompts
    Skip interactive prompts (use with connection name parameters).

.EXAMPLE
    Test-WorkdaySSOConfiguration -EnvironmentId "00000000-0000-0000-0000-000000000000"

.EXAMPLE
    Test-WorkdaySSOConfiguration -EnvironmentId $envId -OAuthUserConnection "oauth user" -ISUWQLConnection "isu wql entra" -ISUGenericConnection "isu generic entra" -SkipPrompts

.NOTES
    Version: 2.0.0
    Author: ESS Pre-flight Validator
#>

#region Security Domain Definitions
$script:WorkdaySecurityDomains = @{
    ReadWorkflows = @(
        @{ Workflow = "Employee ID"; Domain = "Worker Data: Worker ID"; IsPII = $false },
        @{ Workflow = "Company Code"; Domain = "Worker Data: Current Staffing Information"; IsPII = $false },
        @{ Workflow = "Cost Center"; Domain = "Worker Data: Current Staffing Information"; IsPII = $false },
        @{ Workflow = "Base Compensation"; Domain = "Worker Data: Compensation"; IsPII = $false },
        @{ Workflow = "Compensation Ratio"; Domain = "Worker Data: Compensation + Setup: Compensation Packages"; IsPII = $false },
        @{ Workflow = "Service Anniversary"; Domain = "Worker Data: Employment Information"; IsPII = $false },
        @{ Workflow = "Hire Date"; Domain = "Worker Data: Employment Information"; IsPII = $false },
        @{ Workflow = "Employment Information"; Domain = "Worker Data: Employment Information"; IsPII = $false },
        @{ Workflow = "Position Number"; Domain = "Worker Data: Current Staffing Information"; IsPII = $false },
        @{ Workflow = "Emergency Contact"; Domain = "Person Data: Emergency Contacts"; IsPII = $true },
        @{ Workflow = "Certifications"; Domain = "Worker Data: Qualifications"; IsPII = $false },
        @{ Workflow = "National IDs"; Domain = "Worker Data: National Identifiers"; IsPII = $true },
        @{ Workflow = "Passports"; Domain = "Worker Data: Government IDs"; IsPII = $true },
        @{ Workflow = "Visas"; Domain = "Worker Data: Government IDs"; IsPII = $true },
        @{ Workflow = "Language Information"; Domain = "Worker Data: Skills and Experience"; IsPII = $false }
    )
    WriteWorkflows = @(
        @{ Workflow = "Update Email"; Domain = "Person Data: Work Email"; BusinessProcess = "BP: Home Contact Change" },
        @{ Workflow = "Update Phone"; Domain = "Person Data: Work Contact Information"; BusinessProcess = "BP: Home Contact Change" }
    )
    ISU_WQL = @(
        "Workday Accounts (Get)",
        "Custom Report Creation (View)",
        "Person Data: Work Email (Get)",
        "Worker Data: Current Staffing Information (Get)",
        "Worker Data: Worker ID (Get)",
        "Setup: Tenant Setup - Reporting and Analytics (Get)"
    )
    ISU_Generic = @(
        "Integration Build (Put)",
        "Job Information (Put)",
        "Setup: Compensation Packages (Put)"
    )
}

$script:TestPatterns = @(
    @{ Test = "Hello Test"; Action = "Open agent, check greeting"; Expected = "Your name appears"; FailCheck = "ISU_WQL permissions" },
    @{ Test = "Hire Date"; Action = 'Ask "What is my hire date?"'; Expected = "Returns date"; FailCheck = "Worker Data: Employment Information" },
    @{ Test = "Salary"; Action = 'Ask "What is my salary?"'; Expected = "Returns compensation"; FailCheck = "Worker Data: Compensation" },
    @{ Test = "Update Phone"; Action = 'Ask "Update my phone to 555-1234"'; Expected = "Confirmation"; FailCheck = "BP: Home Contact Change" }
)
#endregion

function Test-WorkdaySSOConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvironmentId,
        [string]$OAuthUserConnection,
        [string]$ISUWQLConnection,
        [string]$ISUGenericConnection,
        [string]$DataverseConnection,
        [switch]$GenerateChecklist,
        [switch]$SkipPrompts,
        [string]$OutputPath = "."
    )
    
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "           WORKDAY SSO CONFIGURATION VALIDATOR v2.0                   " -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    #region Get All Connections
    Write-Host "  Scanning connections in environment..." -ForegroundColor Gray
    
    try {
        $allConnections = Get-AdminPowerAppConnection -EnvironmentName $EnvironmentId -ErrorAction Stop
        $workdayConnections = $allConnections | Where-Object { $_.ConnectorName -eq 'shared_workdaysoap' -and $_.Statuses[0].Status -eq 'Connected' }
        $dataverseConnections = $allConnections | Where-Object { $_.ConnectorName -eq 'shared_commondataserviceforapps' -and $_.Statuses[0].Status -eq 'Connected' }
        
        Write-Host "  Found $($workdayConnections.Count) Workday + $($dataverseConnections.Count) Dataverse connections" -ForegroundColor Green
        Write-Host ""
    }
    catch {
        Write-Host "  ERROR scanning connections: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
    #endregion
    
    #region Auto-Detect Best Matches
    function Find-BestMatch {
        param($Connections, $Patterns)
        foreach ($pattern in $Patterns) {
            $match = $Connections | Where-Object { $_.DisplayName -match $pattern } | Select-Object -First 1
            if ($match) { return $match }
        }
        return $null
    }
    
    $detectedOAuth = Find-BestMatch -Connections $workdayConnections -Patterns @('oauth', 'user.*oauth', 'oauthuser')
    $detectedWQL = Find-BestMatch -Connections $workdayConnections -Patterns @('wql', 'context', 'isu.*wql')
    $detectedGeneric = Find-BestMatch -Connections $workdayConnections -Patterns @('generic(?!.*wql)', 'isu.*generic')
    $detectedDataverse = $dataverseConnections | Select-Object -First 1
    #endregion
    
    #region Connection Setup
    Write-Host "=======================================================================" -ForegroundColor DarkCyan
    Write-Host "  ESS REQUIRES 4 CONNECTIONS - LET'S IDENTIFY YOURS" -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  TIP: Find connection names at:" -ForegroundColor Yellow
    Write-Host "  https://make.powerapps.com/environments/$EnvironmentId/connections" -ForegroundColor Gray
    Write-Host ""
    
    $confirmedConnections = @{}
    
    # Helper function for prompts
    function Get-ConnectionConfirmation {
        param(
            [string]$Label,
            [string]$Purpose,
            [string]$DetectedName,
            [string]$ProvidedName,
            [bool]$SkipPrompts
        )
        
        Write-Host "  +-----------------------------------------------------------------+" -ForegroundColor DarkGray
        Write-Host "  | $($Label.PadRight(63)) |" -ForegroundColor White
        Write-Host "  | $($Purpose.PadRight(63)) |" -ForegroundColor DarkGray
        Write-Host "  +-----------------------------------------------------------------+" -ForegroundColor DarkGray
        
        if ($ProvidedName) {
            Write-Host "     Using provided: " -NoNewline -ForegroundColor Gray
            Write-Host "$ProvidedName" -ForegroundColor Green
            Write-Host ""
            return $ProvidedName
        }
        
        if ($DetectedName) {
            Write-Host "     Auto-detected: " -NoNewline -ForegroundColor Gray
            Write-Host "$DetectedName" -ForegroundColor Yellow
        } else {
            Write-Host "     Auto-detected: " -NoNewline -ForegroundColor Gray
            Write-Host "(none found)" -ForegroundColor DarkGray
        }
        
        if ($SkipPrompts) {
            Write-Host ""
            return $DetectedName
        }
        
        $default = if ($DetectedName) { $DetectedName } else { "" }
        Write-Host -NoNewline "     Confirm or enter name [$default]: " -ForegroundColor Cyan
        $userInput = Read-Host
        $result = if ([string]::IsNullOrWhiteSpace($userInput)) { $default } else { $userInput.Trim() }
        Write-Host ""
        return $result
    }
    
    # 1. OAuthUser
    $confirmedConnections['OAuthUser'] = Get-ConnectionConfirmation `
        -Label "1. OAuthUser Connection" `
        -Purpose "YOUR identity for employee data queries (SSO)" `
        -DetectedName $(if ($detectedOAuth) { $detectedOAuth.DisplayName } else { $null }) `
        -ProvidedName $OAuthUserConnection `
        -SkipPrompts $SkipPrompts
    
    # 2. ISU_WQL
    $confirmedConnections['ISU_WQL'] = Get-ConnectionConfirmation `
        -Label "2. Context Generic User (ISU_WQL)" `
        -Purpose "Maps your UPN to Workday Employee ID via RaaS report" `
        -DetectedName $(if ($detectedWQL) { $detectedWQL.DisplayName } else { $null }) `
        -ProvidedName $ISUWQLConnection `
        -SkipPrompts $SkipPrompts
    
    # 3. ISU_Generic
    $confirmedConnections['ISU_Generic'] = Get-ConnectionConfirmation `
        -Label "3. Generic User (ISU_Generic)" `
        -Purpose "Template retrieval and API integration" `
        -DetectedName $(if ($detectedGeneric) { $detectedGeneric.DisplayName } else { $null }) `
        -ProvidedName $ISUGenericConnection `
        -SkipPrompts $SkipPrompts
    
    # 4. Dataverse
    $confirmedConnections['Dataverse'] = Get-ConnectionConfirmation `
        -Label "4. Dataverse Connection" `
        -Purpose "Access to ESS templates in Dataverse" `
        -DetectedName $(if ($detectedDataverse) { $detectedDataverse.DisplayName } else { $null }) `
        -ProvidedName $DataverseConnection `
        -SkipPrompts $SkipPrompts
    #endregion
    
    #region Validate Connections
    Write-Host "=======================================================================" -ForegroundColor DarkCyan
    Write-Host "  VALIDATING YOUR CONNECTIONS" -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor DarkCyan
    Write-Host ""
    
    $validationResults = @()
    $passCount = 0
    $failCount = 0
    
    foreach ($connType in @('OAuthUser', 'ISU_WQL', 'ISU_Generic', 'Dataverse')) {
        $connName = $confirmedConnections[$connType]
        
        if ([string]::IsNullOrWhiteSpace($connName)) {
            Write-Host "  [WARN] $connType`: " -NoNewline -ForegroundColor Yellow
            Write-Host "Skipped (no name provided)" -ForegroundColor DarkGray
            $validationResults += [PSCustomObject]@{
                Connection = $connType
                Name = "(skipped)"
                Status = "Skipped"
                Details = "No connection name provided"
            }
            continue
        }
        
        # Find the actual connection
        $searchPool = if ($connType -eq 'Dataverse') { $dataverseConnections } else { $workdayConnections }
        $foundConn = $searchPool | Where-Object { $_.DisplayName -eq $connName } | Select-Object -First 1
        
        if ($foundConn) {
            $status = $foundConn.Statuses[0].Status
            if ($status -eq 'Connected') {
                Write-Host "  [PASS] $connType`: " -NoNewline -ForegroundColor Green
                Write-Host "`"$connName`" - Connected" -ForegroundColor White
                $passCount++
                $validationResults += [PSCustomObject]@{
                    Connection = $connType
                    Name = $connName
                    Status = "Passed"
                    Details = "Connected"
                }
            } else {
                Write-Host "  [FAIL] $connType`: " -NoNewline -ForegroundColor Red
                Write-Host "`"$connName`" - $status" -ForegroundColor Yellow
                $failCount++
                $validationResults += [PSCustomObject]@{
                    Connection = $connType
                    Name = $connName
                    Status = "Failed"
                    Details = $status
                }
            }
        } else {
            Write-Host "  [FAIL] $connType`: " -NoNewline -ForegroundColor Red
            Write-Host "`"$connName`" - NOT FOUND" -ForegroundColor Yellow
            $failCount++
            $validationResults += [PSCustomObject]@{
                Connection = $connType
                Name = $connName
                Status = "Failed"
                Details = "Connection not found"
            }
        }
    }
    
    Write-Host ""
    Write-Host "  -----------------------------------------------------------------------" -ForegroundColor DarkGray
    if ($failCount -eq 0 -and $passCount -ge 3) {
        Write-Host "  CONNECTION CHECK: PASSED ($passCount/4 validated)" -ForegroundColor Green
    } elseif ($failCount -gt 0) {
        Write-Host "  CONNECTION CHECK: $failCount ISSUE(S) FOUND" -ForegroundColor Red
    } else {
        Write-Host "  CONNECTION CHECK: $passCount/4 validated" -ForegroundColor Yellow
    }
    Write-Host ""
    #endregion
    
    #region Security Domain Checklist
    Write-Host "=======================================================================" -ForegroundColor DarkCyan
    Write-Host "  WORKDAY SECURITY DOMAINS (For Workday Admin)" -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  These permissions must be configured IN WORKDAY by your Workday Admin." -ForegroundColor Yellow
    Write-Host "  We cannot test these remotely - they require Workday console access." -ForegroundColor DarkGray
    Write-Host ""
    
    # Employee as Self - Read
    Write-Host "  +-----------------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "  |  EMPLOYEE AS SELF - READ PERMISSIONS (GET via Integration)      |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------------+" -ForegroundColor DarkCyan
    foreach ($wf in $script:WorkdaySecurityDomains.ReadWorkflows) {
        $pii = if ($wf.IsPII) { " [PII]" } else { "" }
        Write-Host "     [ ] $($wf.Workflow.PadRight(22)) -> $($wf.Domain)$pii" -ForegroundColor White
    }
    Write-Host ""
    
    # Employee as Self - Write
    Write-Host "  +-----------------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "  |  EMPLOYEE AS SELF - WRITE PERMISSIONS (GET+PUT)                 |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------------+" -ForegroundColor DarkCyan
    foreach ($wf in $script:WorkdaySecurityDomains.WriteWorkflows) {
        Write-Host "     [ ] $($wf.Workflow.PadRight(22)) -> $($wf.Domain)" -ForegroundColor White
        Write-Host "                                  + $($wf.BusinessProcess)" -ForegroundColor Gray
    }
    Write-Host ""
    
    # ISU Accounts
    Write-Host "  +-----------------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "  |  ISU SERVICE ACCOUNT PERMISSIONS                                |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "     ISSG_WQL_COPILOT (for context/reports):" -ForegroundColor Yellow
    foreach ($domain in $script:WorkdaySecurityDomains.ISU_WQL) {
        Write-Host "       [ ] $domain" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "     ISSG_Generic_COPILOT (for templates/integration):" -ForegroundColor Yellow
    foreach ($domain in $script:WorkdaySecurityDomains.ISU_Generic) {
        Write-Host "       [ ] $domain" -ForegroundColor White
    }
    Write-Host ""
    #endregion
    
    #region Test Patterns
    Write-Host "=======================================================================" -ForegroundColor DarkCyan
    Write-Host "  QUICK TESTS (Validate Permissions Are Working)" -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor DarkCyan
    Write-Host ""
    
    $testNum = 1
    foreach ($test in $script:TestPatterns) {
        Write-Host "  $testNum. $($test.Test)" -ForegroundColor White
        Write-Host "     Do: $($test.Action)" -ForegroundColor Gray
        Write-Host "     Expect: $($test.Expected)" -ForegroundColor Green
        Write-Host "     If fails: Check $($test.FailCheck)" -ForegroundColor Yellow
        Write-Host ""
        $testNum++
    }
    #endregion
    
    #region Generate Checklist File
    if ($GenerateChecklist) {
        Write-Host "=======================================================================" -ForegroundColor DarkCyan
        Write-Host "  GENERATING CHECKLIST FILE..." -ForegroundColor Cyan
        Write-Host "=======================================================================" -ForegroundColor DarkCyan
        Write-Host ""
        
        $checklistPath = Join-Path $OutputPath "WorkdaySecurityChecklist_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        
        $checklistContent = @"
================================================================================
              WORKDAY SECURITY DOMAIN CHECKLIST FOR ESS
              Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
================================================================================

INSTRUCTIONS: Complete this checklist in Workday Admin console.
Reference: https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/workday#task-6-security-configuration

================================================================================
SECTION 1: EMPLOYEE AS SELF - READ PERMISSIONS
================================================================================
Add "Employee as self" security group with GET access (Integration Permissions)

"@
        foreach ($wf in $script:WorkdaySecurityDomains.ReadWorkflows) {
            $pii = if ($wf.IsPII) { " [PII]" } else { "" }
            $checklistContent += "[ ] $($wf.Workflow)$pii`n    Domain: $($wf.Domain)`n`n"
        }
        
        $checklistContent += @"
================================================================================
SECTION 2: EMPLOYEE AS SELF - WRITE PERMISSIONS  
================================================================================
Add "Employee as self" with GET+PUT access AND Business Process initiate

"@
        foreach ($wf in $script:WorkdaySecurityDomains.WriteWorkflows) {
            $checklistContent += "[ ] $($wf.Workflow)`n    Domain: $($wf.Domain) (Get + Put)`n    Business Process: $($wf.BusinessProcess) (Initiate)`n`n"
        }
        
        $checklistContent += @"
================================================================================
SECTION 3: ISU_WQL_COPILOT (ISSG_WQL_COPILOT)
================================================================================

"@
        foreach ($domain in $script:WorkdaySecurityDomains.ISU_WQL) {
            $checklistContent += "[ ] $domain`n"
        }
        
        $checklistContent += @"

================================================================================
SECTION 4: ISU_GENERIC_COPILOT (ISSG_Generic_COPILOT)
================================================================================

"@
        foreach ($domain in $script:WorkdaySecurityDomains.ISU_Generic) {
            $checklistContent += "[ ] $domain`n"
        }
        
        $checklistContent += @"

================================================================================
FINAL STEP: Run "Activate Pending Security Policy Changes" in Workday
================================================================================
"@
        
        $checklistContent | Out-File -FilePath $checklistPath -Encoding UTF8
        
        Write-Host "  Checklist saved to:" -ForegroundColor Green
        Write-Host "  $checklistPath" -ForegroundColor White
        Write-Host ""
        Write-Host "  Send this file to your Workday Administrator!" -ForegroundColor Yellow
        Write-Host ""
    }
    #endregion
    
    #region Final Summary
    Write-Host "=======================================================================" -ForegroundColor DarkCyan
    Write-Host "  SUMMARY" -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  Connections: $passCount passed, $failCount failed" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Yellow" })
    Write-Host "  Security Domains: 15 READ + 2 WRITE + 9 ISU (requires Workday Admin)" -ForegroundColor Cyan
    Write-Host ""
    
    if ($failCount -eq 0 -and $passCount -ge 3) {
        Write-Host "  POWER PLATFORM SIDE LOOKS GOOD!" -ForegroundColor Green
        Write-Host "  Next: Verify Workday security domains with your Workday Admin" -ForegroundColor White
    } else {
        Write-Host "  FIX CONNECTION ISSUES FIRST" -ForegroundColor Yellow
        Write-Host "  Then: Verify Workday security domains" -ForegroundColor White
    }
    Write-Host ""
    #endregion
    
    return $validationResults
}

# Export for module use (silently ignore when dot-sourced)
try { Export-ModuleMember -Function Test-WorkdaySSOConfiguration } catch { }

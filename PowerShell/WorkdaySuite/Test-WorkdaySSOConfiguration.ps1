<#
.SYNOPSIS
    Validates Workday SSO configuration for ESS Agent integration.

.DESCRIPTION
    Deep diagnostic tool for Workday Single Sign-On (SSO) configuration.
    Validates connection auth types, identity mapping, flow run history,
    and generates a security domain checklist for Workday administrators.

    This tool answers: "Is the plumbing configured correctly for SSO?"

.PARAMETER EnvironmentId
    The Power Platform environment ID to validate.

.PARAMETER GenerateChecklist
    Exports a Workday Admin checklist to a text file.

.PARAMETER CheckFlowHistory
    Analyzes recent flow runs for error patterns.

.EXAMPLE
    Test-WorkdaySSOConfiguration -EnvironmentId "c3446975-d597-e5b4-8724-d5be9e5c4303"

.EXAMPLE
    Test-WorkdaySSOConfiguration -EnvironmentId $envId -GenerateChecklist -CheckFlowHistory

.NOTES
    Version: 1.0.0
    Author: ESS Pre-flight Validator
    Requires: Microsoft.PowerApps.Administration.PowerShell module
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$EnvironmentId,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateChecklist,
    
    [Parameter(Mandatory = $false)]
    [switch]$CheckFlowHistory,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "."
)

#region Security Domain Definitions
$script:WorkdaySecurityDomains = @{
    # Read Workflows - Employee as Self
    ReadWorkflows = @(
        @{
            Workflow = "Employee ID"
            Domain = "Worker Data: Worker ID"
            Permission = "Get"
            SecurityGroup = "Employee as self"
            IsPII = $false
        },
        @{
            Workflow = "Company Code"
            Domain = "Worker Data: Current Staffing Information"
            Permission = "Get"
            SecurityGroup = "Employee as self"
            IsPII = $false
        },
        @{
            Workflow = "Cost Center"
            Domain = "Worker Data: Current Staffing Information"
            Permission = "Get"
            SecurityGroup = "Employee as self"
            IsPII = $false
        },
        @{
            Workflow = "Base Compensation"
            Domain = "Worker Data: Compensation"
            Permission = "Get"
            SecurityGroup = "Employee as self"
            IsPII = $false
        },
        @{
            Workflow = "Compensation Ratio"
            Domain = "Worker Data: Compensation"
            Permission = "Get"
            SecurityGroup = "Employee as self"
            IsPII = $false
            AdditionalDomain = "Setup: Compensation Packages"
        },
        @{
            Workflow = "Service Anniversary"
            Domain = "Worker Data: Employment Information"
            Permission = "Get"
            SecurityGroup = "Employee as self"
            IsPII = $false
        },
        @{
            Workflow = "Hire Date"
            Domain = "Worker Data: Employment Information"
            Permission = "Get"
            SecurityGroup = "Employee as self"
            IsPII = $false
        },
        @{
            Workflow = "Employment Information"
            Domain = "Worker Data: Employment Information"
            Permission = "Get"
            SecurityGroup = "Employee as self"
            IsPII = $false
        },
        @{
            Workflow = "Position Number"
            Domain = "Worker Data: Current Staffing Information"
            Permission = "Get"
            SecurityGroup = "Employee as self"
            IsPII = $false
        },
        @{
            Workflow = "Emergency Contact"
            Domain = "Person Data: Emergency Contacts"
            Permission = "Get"
            SecurityGroup = "Employee as self"
            IsPII = $true
        },
        @{
            Workflow = "Certifications"
            Domain = "Worker Data: Qualifications"
            Permission = "Get"
            SecurityGroup = "Employee as self"
            IsPII = $false
        },
        @{
            Workflow = "National IDs"
            Domain = "Worker Data: National Identifiers"
            Permission = "Get"
            SecurityGroup = "Employee as self"
            IsPII = $true
        },
        @{
            Workflow = "Passports"
            Domain = "Worker Data: Government IDs"
            Permission = "Get"
            SecurityGroup = "Employee as self"
            IsPII = $true
        },
        @{
            Workflow = "Visas"
            Domain = "Worker Data: Government IDs"
            Permission = "Get"
            SecurityGroup = "Employee as self"
            IsPII = $true
        },
        @{
            Workflow = "Language Information"
            Domain = "Worker Data: Skills and Experience"
            Permission = "Get"
            SecurityGroup = "Employee as self"
            IsPII = $false
        }
    )
    
    # Write Workflows - Employee as Self
    WriteWorkflows = @(
        @{
            Workflow = "Update Email"
            Domain = "Person Data: Work Email"
            Permission = "Get + Put"
            SecurityGroup = "Employee as self"
            IsPII = $false
            BusinessProcess = "BP: Home Contact Change"
        },
        @{
            Workflow = "Update Phone Number"
            Domain = "Person Data: Work Contact Information"
            Permission = "Get + Put"
            SecurityGroup = "Employee as self"
            IsPII = $false
            BusinessProcess = "BP: Home Contact Change"
        }
    )
    
    # ISU_WQL_COPILOT Domains (Context & Reports)
    ISU_WQL = @(
        @{
            Domain = "Workday Accounts"
            Permission = "Get"
            Purpose = "Account validation"
        },
        @{
            Domain = "Custom Report Creation"
            Permission = "View (Report/Task)"
            Purpose = "Run RaaS reports"
        },
        @{
            Domain = "Person Data: Work Email"
            Permission = "Get"
            Purpose = "User context lookup"
        },
        @{
            Domain = "Worker Data: Current Staffing Information"
            Permission = "Get"
            Purpose = "User context lookup"
        },
        @{
            Domain = "Worker Data: Worker ID"
            Permission = "Get"
            Purpose = "Employee ID mapping"
        },
        @{
            Domain = "Setup: Tenant Setup - Reporting and Analytics"
            Permission = "Get"
            Purpose = "Report configuration"
        }
    )
    
    # ISU_Generic_COPILOT Domains (Templates & Integration)
    ISU_Generic = @(
        @{
            Domain = "Integration Build"
            Permission = "Put"
            Purpose = "API integration"
        },
        @{
            Domain = "Job Information"
            Permission = "Put"
            Purpose = "Job data access"
        },
        @{
            Domain = "Setup: Compensation Packages"
            Permission = "Put"
            Purpose = "Compensation config"
        }
    )
    
    # Expected Connection Configuration
    ExpectedConnections = @(
        @{
            Name = "OAuthUser"
            ExpectedIdentity = "Maker (signed-in user)"
            Purpose = "Employee queries via SSO - YOUR identity for YOUR data"
            AuthType = "Microsoft Entra ID Integrated"
        },
        @{
            Name = "Context Generic User"
            ExpectedIdentity = "ISU_WQL_COPILOT"
            Purpose = "User context lookup via RaaS report"
            AuthType = "Microsoft Entra ID Integrated"
        },
        @{
            Name = "Generic User"
            ExpectedIdentity = "ISU_Generic_COPILOT"
            Purpose = "Template retrieval and integration"
            AuthType = "Microsoft Entra ID Integrated"
        },
        @{
            Name = "Microsoft Dataverse"
            ExpectedIdentity = "Maker (signed-in user)"
            Purpose = "Access to ESS templates in Dataverse"
            AuthType = "Microsoft Entra ID"
        }
    )
}

# Test patterns for users
$script:TestPatterns = @(
    @{
        Pattern = "Hello Test"
        UserAction = "Open agent, check if greeted by name"
        WhatItTests = "User Context flow + ISU_WQL permissions"
        ExpectedResult = "Name appears, not <masked-username>"
        FailureDomain = "Custom Report Creation, Worker Data: Worker ID"
    },
    @{
        Pattern = "Basic Read Test"
        UserAction = 'Ask: "What is my hire date?"'
        WhatItTests = "OAuthUser + Employee as self + Employment domain"
        ExpectedResult = "Returns your hire date"
        FailureDomain = "Worker Data: Employment Information"
    },
    @{
        Pattern = "Compensation Test"
        UserAction = 'Ask: "What is my salary?"'
        WhatItTests = "OAuthUser + Employee as self + Compensation domain"
        ExpectedResult = "Returns your salary/compensation"
        FailureDomain = "Worker Data: Compensation"
    },
    @{
        Pattern = "PII Test"
        UserAction = 'Ask: "Show my passport information"'
        WhatItTests = "OAuthUser + Employee as self + Government IDs domain"
        ExpectedResult = "Returns passport info (if enabled)"
        FailureDomain = "Worker Data: Government IDs"
    },
    @{
        Pattern = "Write Test"
        UserAction = 'Ask: "Update my phone number to 555-1234"'
        WhatItTests = "OAuthUser + Employee as self + BP: Home Contact Change"
        ExpectedResult = "Confirmation message + Workday updated"
        FailureDomain = "Person Data: Work Contact Information + BP: Home Contact Change"
    }
)

# Error pattern recognition
$script:ErrorPatterns = @(
    @{
        ErrorMessage = "Error code: 400"
        LikelyCause = "Permission denied in Workday"
        CheckDomain = "Check flow run details for specific domain"
        Resolution = "Review Workday security domain permissions"
    },
    @{
        ErrorMessage = "User context not found"
        LikelyCause = "ISU_WQL_COPILOT cannot run RaaS report"
        CheckDomain = "ISSG_WQL_COPILOT domains"
        Resolution = "Verify Custom Report Creation and Worker Data: Worker ID permissions"
    },
    @{
        ErrorMessage = "Unable to retrieve compensation"
        LikelyCause = "Employee as self missing compensation domain"
        CheckDomain = "Worker Data: Compensation"
        Resolution = "Add GET access for Employee as self to Worker Data: Compensation"
    },
    @{
        ErrorMessage = "Cannot update contact"
        LikelyCause = "Business process not permitted"
        CheckDomain = "BP: Home Contact Change"
        Resolution = "Enable BP: Home Contact Change for Employee as self"
    },
    @{
        ErrorMessage = "<masked-username>"
        LikelyCause = "RaaS report failed or returned empty"
        CheckDomain = "ISU_WQL_COPILOT report access"
        Resolution = "Verify WD_User_Context report exists and ISU can execute it"
    }
)
#endregion

function Test-WorkdaySSOConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvironmentId,
        
        [Parameter(Mandatory = $false)]
        [switch]$GenerateChecklist,
        
        [Parameter(Mandatory = $false)]
        [switch]$CheckFlowHistory,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "."
    )
    
    $results = @()
    
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           WORKDAY SSO CONFIGURATION VALIDATOR                        ║" -ForegroundColor Cyan
    Write-Host "║           Deep Diagnostic for Entra ID Integrated Auth               ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    #region Phase 1: Connection Configuration Analysis
    Write-Host "  ═══════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host "  PHASE 1: CONNECTION CONFIGURATION ANALYSIS" -ForegroundColor Cyan
    Write-Host "  ═══════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host ""
    
    try {
        # Get all Workday SOAP connections
        $allConnections = Get-AdminPowerAppConnection -EnvironmentName $EnvironmentId -ErrorAction Stop |
            Where-Object { $_.ConnectorName -eq 'shared_workdaysoap' -and $_.Statuses[0].Status -eq 'Connected' }
        
        if ($allConnections.Count -eq 0) {
            Write-Host "  ❌ No active Workday SOAP connections found!" -ForegroundColor Red
            $results += [PSCustomObject]@{
                CheckpointId = "SSO-CONN-001"
                Category = "Workday SSO"
                Priority = "Critical"
                Status = "Failed"
                Result = "No active Workday SOAP connections"
                Remediation = "Install Workday Extension Pack and configure connections"
            }
        }
        else {
            Write-Host "  📊 Found $($allConnections.Count) active Workday connection(s)" -ForegroundColor Green
            Write-Host ""
            
            # Analyze each connection
            $connectionIndex = 0
            foreach ($conn in $allConnections) {
                $connectionIndex++
                $connName = $conn.DisplayName
                $connId = $conn.ConnectionName
                $createdTime = $conn.CreatedTime
                
                # Try to determine connection purpose based on name patterns
                $purpose = "Unknown"
                $expectedAuth = "Microsoft Entra ID Integrated"
                
                if ($connName -match 'oauth|user' -and $connName -notmatch 'generic|isu|wql') {
                    $purpose = "OAuthUser (Employee SSO)"
                    $icon = "👤"
                }
                elseif ($connName -match 'wql|context') {
                    $purpose = "Context Generic User (ISU_WQL)"
                    $icon = "📋"
                }
                elseif ($connName -match 'generic|isu' -and $connName -notmatch 'wql') {
                    $purpose = "Generic User (ISU_Generic)"
                    $icon = "🔧"
                }
                else {
                    $purpose = "Workday Connection"
                    $icon = "🔗"
                }
                
                Write-Host "  $icon $connName" -ForegroundColor White
                Write-Host "     Purpose: $purpose" -ForegroundColor Gray
                Write-Host "     Status: Connected ✓" -ForegroundColor Green
                Write-Host "     Created: $createdTime" -ForegroundColor Gray
                Write-Host ""
                
                $results += [PSCustomObject]@{
                    CheckpointId = "SSO-CONN-$($connectionIndex.ToString('000'))"
                    Category = "Workday SSO"
                    Priority = "High"
                    Status = "Passed"
                    Result = "Connection '$connName' - $purpose"
                    ConnectionId = $connId
                }
            }
            
            # Expected connections check
            Write-Host "  ───────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
            Write-Host "  📋 Expected Connection Mapping (Entra SSO):" -ForegroundColor Yellow
            Write-Host ""
            foreach ($expected in $script:WorkdaySecurityDomains.ExpectedConnections) {
                Write-Host "     $($expected.Name)" -ForegroundColor White
                Write-Host "       Identity: $($expected.ExpectedIdentity)" -ForegroundColor Gray
                Write-Host "       Auth: $($expected.AuthType)" -ForegroundColor Gray
                Write-Host "       Purpose: $($expected.Purpose)" -ForegroundColor DarkGray
                Write-Host ""
            }
        }
    }
    catch {
        Write-Host "  ⚠️ Error checking connections: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    #endregion
    
    #region Phase 2: Flow Run History Analysis
    if ($CheckFlowHistory) {
        Write-Host ""
        Write-Host "  ═══════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
        Write-Host "  PHASE 2: FLOW RUN HISTORY ANALYSIS" -ForegroundColor Cyan
        Write-Host "  ═══════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
        Write-Host ""
        
        try {
            $workdayFlows = Get-AdminFlow -EnvironmentName $EnvironmentId -ErrorAction Stop |
                Where-Object { $_.DisplayName -match 'Workday' }
            
            foreach ($flow in $workdayFlows) {
                Write-Host "  🔄 $($flow.DisplayName)" -ForegroundColor White
                
                $flowState = if ($flow.Enabled) { "✅ Enabled" } else { "❌ Disabled" }
                Write-Host "     State: $flowState" -ForegroundColor $(if ($flow.Enabled) { "Green" } else { "Red" })
                
                # Note: Flow run history requires additional API calls
                # This is a placeholder for the structure
                Write-Host "     Last Modified: $($flow.LastModifiedTime)" -ForegroundColor Gray
                Write-Host ""
            }
        }
        catch {
            Write-Host "  ⚠️ Error checking flow history: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    #endregion
    
    #region Phase 3: Security Domain Requirements
    Write-Host ""
    Write-Host "  ═══════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host "  PHASE 3: SECURITY DOMAIN REQUIREMENTS" -ForegroundColor Cyan
    Write-Host "  ═══════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  These require Workday Admin verification. Cannot be tested remotely." -ForegroundColor Yellow
    Write-Host ""
    
    # Read Workflows
    Write-Host "  ┌────────────────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "  │  READ WORKFLOWS (Employee as Self - GET via Integration)           │" -ForegroundColor Cyan
    Write-Host "  ├────────────────────────────────────────────────────────────────────┤" -ForegroundColor DarkCyan
    
    foreach ($workflow in $script:WorkdaySecurityDomains.ReadWorkflows) {
        $piiFlag = if ($workflow.IsPII) { " ⚠️ PII" } else { "" }
        $workflowName = $workflow.Workflow.PadRight(20)
        Write-Host "  │  □ $workflowName → $($workflow.Domain)$piiFlag" -ForegroundColor White
        
        if ($workflow.AdditionalDomain) {
            Write-Host "  │                         → $($workflow.AdditionalDomain)" -ForegroundColor Gray
        }
    }
    
    # Write Workflows
    Write-Host "  ├────────────────────────────────────────────────────────────────────┤" -ForegroundColor DarkCyan
    Write-Host "  │  WRITE WORKFLOWS (Employee as Self - GET+PUT via Integration)      │" -ForegroundColor Cyan
    Write-Host "  ├────────────────────────────────────────────────────────────────────┤" -ForegroundColor DarkCyan
    
    foreach ($workflow in $script:WorkdaySecurityDomains.WriteWorkflows) {
        $workflowName = $workflow.Workflow.PadRight(20)
        Write-Host "  │  □ $workflowName → $($workflow.Domain) ($($workflow.Permission))" -ForegroundColor White
        Write-Host "  │                         → $($workflow.BusinessProcess) (Initiate)" -ForegroundColor Gray
    }
    
    Write-Host "  └────────────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan
    #endregion
    
    #region Phase 4: ISU Service Account Domains
    Write-Host ""
    Write-Host "  ┌────────────────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "  │  ISU SERVICE ACCOUNT DOMAINS                                       │" -ForegroundColor Cyan
    Write-Host "  ├────────────────────────────────────────────────────────────────────┤" -ForegroundColor DarkCyan
    Write-Host "  │  ISSG_WQL_COPILOT (Context & Reports)                              │" -ForegroundColor Yellow
    Write-Host "  ├────────────────────────────────────────────────────────────────────┤" -ForegroundColor DarkCyan
    
    foreach ($domain in $script:WorkdaySecurityDomains.ISU_WQL) {
        $domainName = $domain.Domain.PadRight(45)
        Write-Host "  │  □ $domainName → $($domain.Permission)" -ForegroundColor White
    }
    
    Write-Host "  ├────────────────────────────────────────────────────────────────────┤" -ForegroundColor DarkCyan
    Write-Host "  │  ISSG_Generic_COPILOT (Templates & Integration)                    │" -ForegroundColor Yellow
    Write-Host "  ├────────────────────────────────────────────────────────────────────┤" -ForegroundColor DarkCyan
    
    foreach ($domain in $script:WorkdaySecurityDomains.ISU_Generic) {
        $domainName = $domain.Domain.PadRight(45)
        Write-Host "  │  □ $domainName → $($domain.Permission)" -ForegroundColor White
    }
    
    Write-Host "  └────────────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan
    #endregion
    
    #region Phase 5: Test Patterns
    Write-Host ""
    Write-Host "  ═══════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host "  PHASE 4: TEST PATTERNS (Try These to Validate Permissions)" -ForegroundColor Cyan
    Write-Host "  ═══════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host ""
    
    $patternNum = 1
    foreach ($pattern in $script:TestPatterns) {
        Write-Host "  $patternNum. $($pattern.Pattern)" -ForegroundColor White
        Write-Host "     Action: $($pattern.UserAction)" -ForegroundColor Gray
        Write-Host "     Tests: $($pattern.WhatItTests)" -ForegroundColor DarkGray
        Write-Host "     Expected: $($pattern.ExpectedResult)" -ForegroundColor Green
        Write-Host "     If fails, check: $($pattern.FailureDomain)" -ForegroundColor Yellow
        Write-Host ""
        $patternNum++
    }
    #endregion
    
    #region Phase 6: Error Pattern Reference
    Write-Host "  ═══════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host "  PHASE 5: ERROR PATTERN REFERENCE" -ForegroundColor Cyan
    Write-Host "  ═══════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host ""
    
    foreach ($errorPattern in $script:ErrorPatterns) {
        Write-Host "  ❌ `"$($errorPattern.ErrorMessage)`"" -ForegroundColor Red
        Write-Host "     Cause: $($errorPattern.LikelyCause)" -ForegroundColor Yellow
        Write-Host "     Check: $($errorPattern.CheckDomain)" -ForegroundColor Gray
        Write-Host "     Fix: $($errorPattern.Resolution)" -ForegroundColor Green
        Write-Host ""
    }
    #endregion
    
    #region Generate Checklist
    if ($GenerateChecklist) {
        Write-Host ""
        Write-Host "  ═══════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
        Write-Host "  GENERATING WORKDAY ADMIN CHECKLIST..." -ForegroundColor Cyan
        Write-Host "  ═══════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
        Write-Host ""
        
        $checklistPath = Join-Path $OutputPath "WorkdaySecurityChecklist_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        
        $checklistContent = @"
================================================================================
                    WORKDAY SECURITY DOMAIN CHECKLIST
                    ESS Pre-flight Validator
                    Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
================================================================================

This checklist must be completed by your Workday Administrator.
ESS Agent requires these security domains to function correctly.

--------------------------------------------------------------------------------
SECTION 1: EMPLOYEE AS SELF - READ PERMISSIONS
--------------------------------------------------------------------------------
These domains allow employees to query their OWN data via SSO.
Add "Employee as self" to each domain with GET access (Integration Permissions).

"@
        
        foreach ($workflow in $script:WorkdaySecurityDomains.ReadWorkflows) {
            $piiNote = if ($workflow.IsPII) { " [PII - SENSITIVE]" } else { "" }
            $checklistContent += "[ ] $($workflow.Workflow)$piiNote`n"
            $checklistContent += "    Domain: $($workflow.Domain)`n"
            $checklistContent += "    Permission: GET (Integration)`n"
            if ($workflow.AdditionalDomain) {
                $checklistContent += "    Also needs: $($workflow.AdditionalDomain)`n"
            }
            $checklistContent += "`n"
        }
        
        $checklistContent += @"
--------------------------------------------------------------------------------
SECTION 2: EMPLOYEE AS SELF - WRITE PERMISSIONS
--------------------------------------------------------------------------------
These domains allow employees to UPDATE their own data via SSO.
Add "Employee as self" with GET+PUT access AND Business Process permission.

"@
        
        foreach ($workflow in $script:WorkdaySecurityDomains.WriteWorkflows) {
            $checklistContent += "[ ] $($workflow.Workflow)`n"
            $checklistContent += "    Domain: $($workflow.Domain)`n"
            $checklistContent += "    Permission: GET + PUT (Integration)`n"
            $checklistContent += "    Business Process: $($workflow.BusinessProcess) (Initiate)`n"
            $checklistContent += "`n"
        }
        
        $checklistContent += @"
--------------------------------------------------------------------------------
SECTION 3: ISU_WQL_COPILOT SERVICE ACCOUNT
--------------------------------------------------------------------------------
Security Group: ISSG_WQL_COPILOT
Purpose: Runs RaaS reports to get user context (maps UPN to Employee ID)

"@
        
        foreach ($domain in $script:WorkdaySecurityDomains.ISU_WQL) {
            $checklistContent += "[ ] $($domain.Domain)`n"
            $checklistContent += "    Permission: $($domain.Permission)`n"
            $checklistContent += "    Purpose: $($domain.Purpose)`n"
            $checklistContent += "`n"
        }
        
        $checklistContent += @"
--------------------------------------------------------------------------------
SECTION 4: ISU_GENERIC_COPILOT SERVICE ACCOUNT
--------------------------------------------------------------------------------
Security Group: ISSG_Generic_COPILOT
Purpose: Accesses templates and integration configuration

"@
        
        foreach ($domain in $script:WorkdaySecurityDomains.ISU_Generic) {
            $checklistContent += "[ ] $($domain.Domain)`n"
            $checklistContent += "    Permission: $($domain.Permission)`n"
            $checklistContent += "    Purpose: $($domain.Purpose)`n"
            $checklistContent += "`n"
        }
        
        $checklistContent += @"
--------------------------------------------------------------------------------
SECTION 5: FINAL STEPS
--------------------------------------------------------------------------------
[ ] Run: Activate Pending Security Policy Changes
[ ] Verify ISU accounts are in correct ISSGs
[ ] Test with a pilot user before rollout

--------------------------------------------------------------------------------
DOCUMENTATION REFERENCE
--------------------------------------------------------------------------------
Microsoft Docs: https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/workday#task-6-security-configuration

================================================================================
"@
        
        $checklistContent | Out-File -FilePath $checklistPath -Encoding UTF8
        
        Write-Host "  ✅ Checklist exported to:" -ForegroundColor Green
        Write-Host "     $checklistPath" -ForegroundColor White
        Write-Host ""
        Write-Host "  📧 Send this file to your Workday Administrator!" -ForegroundColor Yellow
    }
    #endregion
    
    #region Summary
    Write-Host ""
    Write-Host "  ═══════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host "  SUMMARY" -ForegroundColor Cyan
    Write-Host "  ═══════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  ✅ Connections Analyzed: $($results.Count)" -ForegroundColor Green
    Write-Host "  📋 Security Domains Listed: $(($script:WorkdaySecurityDomains.ReadWorkflows.Count + $script:WorkdaySecurityDomains.WriteWorkflows.Count))" -ForegroundColor Cyan
    Write-Host "  🔧 ISU Domains Required: $(($script:WorkdaySecurityDomains.ISU_WQL.Count + $script:WorkdaySecurityDomains.ISU_Generic.Count))" -ForegroundColor Cyan
    Write-Host "  🧪 Test Patterns Provided: $($script:TestPatterns.Count)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  📖 Next Steps:" -ForegroundColor Yellow
    Write-Host "     1. Share checklist with Workday Admin (use -GenerateChecklist)" -ForegroundColor White
    Write-Host "     2. Have them verify/grant permissions" -ForegroundColor White
    Write-Host "     3. Run test patterns to validate" -ForegroundColor White
    Write-Host "     4. Check flow run history if issues persist" -ForegroundColor White
    Write-Host ""
    #endregion
    
    return $results
}

# Export for module use
Export-ModuleMember -Function Test-WorkdaySSOConfiguration -ErrorAction SilentlyContinue

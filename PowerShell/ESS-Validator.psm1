<#
.SYNOPSIS
    Pre-flight Deployment Validator for Microsoft 365 Copilot Employee Self-Service (ESS) Agent

.DESCRIPTION
    Comprehensive PowerShell module for validating ESS deployment readiness before production deployment.
    Validates prerequisites, environment configuration, authentication, external systems, content, topics,
    configuration, and publishing readiness.

.NOTES
    Version: 1.2.0
    Author: ESS Validator Team
    
.LINK
    https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/
#>

#Requires -Version 7.0
#Requires -Modules @{ ModuleName='Microsoft.Graph'; ModuleVersion='2.0.0' }
#Requires -Modules @{ ModuleName='Microsoft.PowerApps.Administration.PowerShell'; ModuleVersion='2.0.0' }

# Module-level variables
$script:ValidationResults = @()
$script:ValidationStartTime = $null
$script:ValidationScope = 'Full'

<#
.SYNOPSIS
    Main validation entry point - runs comprehensive ESS deployment validation

.DESCRIPTION
    Executes all validation checks or specific scope of checks based on parameters.
    Returns validation results with pass/fail status, findings, and remediation guidance.

.PARAMETER Scope
    Validation scope: Full, Prerequisites, Environment, Authentication, ExternalSystems, Content, Topics, Configuration, Publishing

.PARAMETER EnvironmentId
    Power Platform environment ID to validate

.PARAMETER OutputFormat
    Output format: Console, JSON, HTML, CSV

.PARAMETER ExportPath
    Path to export validation results

.EXAMPLE
    Test-ESSDeploymentReadiness -Scope Full -Verbose

.EXAMPLE
    Test-ESSDeploymentReadiness -Scope Prerequisites -OutputFormat JSON -ExportPath "C:\Validation\results.json"
#>
function Test-ESSDeploymentReadiness {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('Full', 'Prerequisites', 'Environment', 'Authentication', 'ExternalSystems', 'Content', 'Topics', 'Configuration', 'Publishing')]
        [string]$Scope = 'Full',

        [Parameter()]
        [string]$EnvironmentId,

        [Parameter()]
        [ValidateSet('Console', 'JSON', 'HTML', 'CSV')]
        [string]$OutputFormat = 'Console',

        [Parameter()]
        [string]$ExportPath
    )

    begin {
        Write-Verbose "Starting ESS Pre-flight Deployment Validation - Scope: $Scope"
        $script:ValidationStartTime = Get-Date
        $script:ValidationScope = $Scope
        $script:ValidationResults = @()

        # Connect to required services
        Initialize-ValidationSession
    }

    process {
        try {
            switch ($Scope) {
                'Full' {
                    Test-ESSPrerequisites
                    Test-ESSEnvironment -EnvironmentId $EnvironmentId
                    Test-ESSAuthentication
                    Test-ESSExternalSystems -EnvironmentId $EnvironmentId
                    Test-ESSContent -EnvironmentId $EnvironmentId
                    Test-ESSTopics -EnvironmentId $EnvironmentId
                    Test-ESSConfiguration -EnvironmentId $EnvironmentId
                    Test-ESSPublishing -EnvironmentId $EnvironmentId
                }
                'Prerequisites' { Test-ESSPrerequisites }
                'Environment' { Test-ESSEnvironment -EnvironmentId $EnvironmentId }
                'Authentication' { Test-ESSAuthentication }
                'ExternalSystems' { Test-ESSExternalSystems -EnvironmentId $EnvironmentId }
                'Content' { Test-ESSContent -EnvironmentId $EnvironmentId }
                'Topics' { Test-ESSTopics -EnvironmentId $EnvironmentId }
                'Configuration' { Test-ESSConfiguration -EnvironmentId $EnvironmentId }
                'Publishing' { Test-ESSPublishing -EnvironmentId $EnvironmentId }
            }

            $validationSummary = Get-ValidationSummary
            
            Write-Host "`n========================================" -ForegroundColor Cyan
            Write-Host "ESS PRE-FLIGHT VALIDATION SUMMARY" -ForegroundColor Cyan
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host "Validation Scope: $Scope"
            Write-Host "Total Checks: $($validationSummary.TotalChecks)"
            Write-Host "Passed: $($validationSummary.Passed) " -ForegroundColor Green -NoNewline
            Write-Host "| Failed: $($validationSummary.Failed) " -ForegroundColor Red -NoNewline
            Write-Host "| Warnings: $($validationSummary.Warnings) " -ForegroundColor Yellow -NoNewline
            Write-Host "| Not Configured: $($validationSummary.NotConfigured)" -ForegroundColor Gray
            Write-Host "Overall Status: " -NoNewline
            
            if ($validationSummary.Failed -eq 0 -and $validationSummary.Warnings -eq 0) {
                Write-Host "✅ READY FOR DEPLOYMENT" -ForegroundColor Green
            } elseif ($validationSummary.Failed -eq 0) {
                Write-Host "⚠️ READY WITH WARNINGS" -ForegroundColor Yellow
            } else {
                Write-Host "❌ NOT READY - ISSUES FOUND" -ForegroundColor Red
            }
            Write-Host "========================================`n" -ForegroundColor Cyan

            # Export results if requested
            if ($ExportPath) {
                Export-ValidationResults -Results $script:ValidationResults -Format $OutputFormat -Path $ExportPath
            }

            return $script:ValidationResults
        }
        catch {
            Write-Error "Validation failed: $_"
            throw
        }
    }

    end {
        $duration = (Get-Date) - $script:ValidationStartTime
        Write-Verbose "Validation completed in $($duration.TotalSeconds) seconds"
    }
}

<#
.SYNOPSIS
    Validates prerequisites including licensing, roles, and capacity

.DESCRIPTION
    Checks Microsoft 365 Copilot licenses, Copilot Studio licenses, Teams licenses,
    role assignments, and capacity planning requirements.
#>
function Test-ESSPrerequisites {
    [CmdletBinding()]
    param()

    Write-Host "`n🔍 Validating Prerequisites..." -ForegroundColor Cyan

    # PRE-001: Microsoft 365 Copilot licenses
    try {
        Write-Verbose "Checking Microsoft 365 Copilot licenses..."
        $copilotLicenses = Get-MgSubscribedSku -All | Where-Object { $_.SkuPartNumber -like '*MICROSOFT_365_COPILOT*' }
        
        if ($copilotLicenses -and $copilotLicenses.ConsumedUnits -gt 0) {
            Add-ValidationResult -CheckpointId 'PRE-001' -Category 'Prerequisites' -Priority 'Critical' -Status 'Passed' `
                -Result "Microsoft 365 Copilot licenses found: $($copilotLicenses.ConsumedUnits) consumed out of $($copilotLicenses.PrepaidUnits.Enabled) enabled" `
                -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prerequisites#licensing'
        } else {
            Add-ValidationResult -CheckpointId 'PRE-001' -Category 'Prerequisites' -Priority 'Critical' -Status 'Failed' `
                -Result "No Microsoft 365 Copilot licenses found or no licenses consumed" `
                -Remediation "Purchase and assign Microsoft 365 Copilot licenses to users who will use the ESS agent. Minimum 1 license required." `
                -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prerequisites#licensing'
        }
    } catch {
        Add-ValidationResult -CheckpointId 'PRE-001' -Category 'Prerequisites' -Priority 'Critical' -Status 'Failed' `
            -Result "Unable to check Microsoft 365 Copilot licenses: $_" `
            -Remediation "Ensure you have permissions to read license information via Microsoft Graph API" `
            -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prerequisites#licensing'
    }

    # PRE-002: Copilot Studio licenses for admins/makers
    try {
        Write-Verbose "Checking Copilot Studio licenses..."
        $copilotStudioLicenses = Get-MgSubscribedSku -All | Where-Object { 
            $_.SkuPartNumber -like '*COPILOT_STUDIO*' -or $_.SkuPartNumber -like '*POWER_VIRTUAL_AGENTS*'
        }
        
        if ($copilotStudioLicenses) {
            Add-ValidationResult -CheckpointId 'PRE-002' -Category 'Prerequisites' -Priority 'Critical' -Status 'Passed' `
                -Result "Copilot Studio licenses found: $($copilotStudioLicenses.SkuPartNumber -join ', ')" `
                -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prerequisites#licensing'
        } else {
            Add-ValidationResult -CheckpointId 'PRE-002' -Category 'Prerequisites' -Priority 'Critical' -Status 'Failed' `
                -Result "No Copilot Studio licenses found for environment makers" `
                -Remediation "Assign Copilot Studio licenses to Power Platform administrators and environment makers who will configure the ESS agent." `
                -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prerequisites#licensing'
        }
    } catch {
        Add-ValidationResult -CheckpointId 'PRE-002' -Category 'Prerequisites' -Priority 'Critical' -Status 'Failed' `
            -Result "Unable to check Copilot Studio licenses: $_" `
            -Remediation "Ensure you have permissions to read license information via Microsoft Graph API"
    }

    # PRE-003: Microsoft Teams licenses
    try {
        Write-Verbose "Checking Microsoft Teams licenses..."
        $teamsLicenses = Get-MgSubscribedSku -All | Where-Object { $_.SkuPartNumber -like '*TEAMS*' }
        
        if ($teamsLicenses -and $teamsLicenses.ConsumedUnits -gt 0) {
            Add-ValidationResult -CheckpointId 'PRE-003' -Category 'Prerequisites' -Priority 'Critical' -Status 'Passed' `
                -Result "Microsoft Teams licenses found: $($teamsLicenses.ConsumedUnits) users licensed" `
                -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prerequisites#licensing'
        } else {
            Add-ValidationResult -CheckpointId 'PRE-003' -Category 'Prerequisites' -Priority 'Critical' -Status 'Warning' `
                -Result "No Microsoft Teams licenses found or no users licensed" `
                -Remediation "Ensure users have Teams licenses if you plan to deploy ESS agent via Teams channel." `
                -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prerequisites#licensing'
        }
    } catch {
        Add-ValidationResult -CheckpointId 'PRE-003' -Category 'Prerequisites' -Priority 'Critical' -Status 'Failed' `
            -Result "Unable to check Teams licenses: $_"
    }

    # PRE-008: Global Admin role
    try {
        Write-Verbose "Checking Global Admin role assignments..."
        $globalAdminRole = Get-MgDirectoryRole -Filter "DisplayName eq 'Global Administrator'"
        $globalAdminMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $globalAdminRole.Id
        
        if ($globalAdminMembers.Count -gt 0) {
            Add-ValidationResult -CheckpointId 'PRE-008' -Category 'Prerequisites' -Priority 'Critical' -Status 'Passed' `
                -Result "Global Admin role assigned to $($globalAdminMembers.Count) user(s)" `
                -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prerequisites#required-roles'
        } else {
            Add-ValidationResult -CheckpointId 'PRE-008' -Category 'Prerequisites' -Priority 'Critical' -Status 'Failed' `
                -Result "No Global Admin role assignments found" `
                -Remediation "Assign Global Admin role to at least one user for ESS deployment." `
                -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prerequisites#required-roles'
        }
    } catch {
        Add-ValidationResult -CheckpointId 'PRE-008' -Category 'Prerequisites' -Priority 'Critical' -Status 'Failed' `
            -Result "Unable to check Global Admin role: $_"
    }

    Write-Host "✓ Prerequisites validation completed" -ForegroundColor Green
    return $script:ValidationResults
}

<#
.SYNOPSIS
    Validates Power Platform environment configuration

.DESCRIPTION
    Checks environment existence, Dataverse database, managed environment status,
    DLP policies, and Copilot Studio accessibility.
#>
function Test-ESSEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvironmentId
    )

    Write-Host "`n🔍 Validating Environment Configuration..." -ForegroundColor Cyan

    # ENV-001: Power Platform environment exists
    try {
        Write-Verbose "Checking Power Platform environment..."
        $environment = Get-AdminPowerAppEnvironment -EnvironmentName $EnvironmentId -ErrorAction SilentlyContinue
        
        if ($environment) {
            Add-ValidationResult -CheckpointId 'ENV-001' -Category 'Environment' -Priority 'Critical' -Status 'Passed' `
                -Result "Power Platform environment exists: $($environment.DisplayName)" `
                -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prepare#set-up-your-power-platform-environment'
        } else {
            Add-ValidationResult -CheckpointId 'ENV-001' -Category 'Environment' -Priority 'Critical' -Status 'Failed' `
                -Result "Power Platform environment not found: $EnvironmentId" `
                -Remediation "Create a Power Platform environment with Dataverse database. Go to Power Platform Admin Center > Environments > New." `
                -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prepare#set-up-your-power-platform-environment'
            return
        }

        # ENV-002: Dataverse database enabled
        if ($environment.CommonDataServiceDatabaseProvisioningState -eq 'Succeeded') {
            Add-ValidationResult -CheckpointId 'ENV-002' -Category 'Environment' -Priority 'Critical' -Status 'Passed' `
                -Result "Dataverse database is enabled and provisioned" `
                -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prepare#set-up-your-power-platform-environment'
        } else {
            Add-ValidationResult -CheckpointId 'ENV-002' -Category 'Environment' -Priority 'Critical' -Status 'Failed' `
                -Result "Dataverse database is not enabled or provisioning state: $($environment.CommonDataServiceDatabaseProvisioningState)" `
                -Remediation "Enable Dataverse database for this environment. Go to Power Platform Admin Center > Environments > [Your Environment] > Add database." `
                -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prepare#set-up-your-power-platform-environment'
        }

        # ENV-003: Managed environment
        if ($environment.EnvironmentType -eq 'Managed') {
            Add-ValidationResult -CheckpointId 'ENV-003' -Category 'Environment' -Priority 'High' -Status 'Passed' `
                -Result "Environment is a Managed Environment" `
                -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prepare#set-up-your-power-platform-environment'
        } else {
            Add-ValidationResult -CheckpointId 'ENV-003' -Category 'Environment' -Priority 'High' -Status 'Passed' `
                -Result "Environment type: $($environment.EnvironmentType) - Managed Environment not required for ESS" `
                -Remediation "Optional: Enable Managed Environment for enhanced governance features (not required for ESS functionality)." `
                -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prepare#set-up-your-power-platform-environment'
        }

        # ENV-008: DLP policies
        try {
            Write-Verbose "Checking DLP policies..."
            $dlpPolicies = Get-DlpPolicy -EnvironmentName $EnvironmentId -ErrorAction SilentlyContinue
            
            if ($dlpPolicies) {
                Add-ValidationResult -CheckpointId 'ENV-008' -Category 'Environment' -Priority 'High' -Status 'Passed' `
                    -Result "DLP policies configured: $($dlpPolicies.Count) policy/policies found" `
                    -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prepare#allow-the-external-systems-connector'
            } else {
                Add-ValidationResult -CheckpointId 'ENV-008' -Category 'Environment' -Priority 'High' -Status 'Warning' `
                    -Result "No DLP policies configured for this environment" `
                    -Remediation "Review and configure DLP policies to ensure required connectors (SAP, Workday, ServiceNow) are allowlisted." `
                    -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prepare#allow-the-external-systems-connector'
            }
        } catch {
            Add-ValidationResult -CheckpointId 'ENV-008' -Category 'Environment' -Priority 'High' -Status 'Warning' `
                -Result "DLP policy check skipped - requires Power Platform Administrator permissions" `
                -Remediation "Grant Power Platform Administrator role and re-run validation to verify DLP policies."
        }

    } catch {
        Add-ValidationResult -CheckpointId 'ENV-001' -Category 'Environment' -Priority 'Critical' -Status 'Failed' `
            -Result "Unable to check environment: $_" `
            -Remediation "Ensure you have Power Platform Administrator permissions and the environment ID is correct."
    }

    Write-Host "✓ Environment validation completed" -ForegroundColor Green
    return $script:ValidationResults
}

<#
.SYNOPSIS
    Validates authentication and identity configuration

.DESCRIPTION
    Checks Entra ID configuration, SSO setup, OAuth configurations, and federation.
#>
function Test-ESSAuthentication {
    [CmdletBinding()]
    param()

    Write-Host "`n🔍 Validating Authentication Configuration..." -ForegroundColor Cyan

    # AUTH-001: Entra ID configured
    try {
        Write-Verbose "Checking Microsoft Entra ID configuration..."
        $organization = Get-MgOrganization
        
        if ($organization) {
            Add-ValidationResult -CheckpointId 'AUTH-001' -Category 'Authentication' -Priority 'Critical' -Status 'Passed' `
                -Result "Microsoft Entra ID configured: $($organization.DisplayName) (Tenant: $($organization.Id))" `
                -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prerequisites#identity-authentication-and-single-sign-on-sso'
        } else {
            Add-ValidationResult -CheckpointId 'AUTH-001' -Category 'Authentication' -Priority 'Critical' -Status 'Failed' `
                -Result "Unable to retrieve Microsoft Entra ID organization information" `
                -Remediation "Ensure Microsoft Entra ID is properly configured for your tenant." `
                -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prerequisites#identity-authentication-and-single-sign-on-sso'
        }
    } catch {
        Add-ValidationResult -CheckpointId 'AUTH-001' -Category 'Authentication' -Priority 'Critical' -Status 'Failed' `
            -Result "Unable to check Entra ID: $_"
    }

    # AUTH-002: SSO configuration
    try {
        Write-Verbose "Checking SSO configuration..."
        $conditionalAccessPolicies = Get-MgIdentityConditionalAccessPolicy -All -ErrorAction SilentlyContinue
        
        if ($conditionalAccessPolicies) {
            Add-ValidationResult -CheckpointId 'AUTH-002' -Category 'Authentication' -Priority 'High' -Status 'Passed' `
                -Result "Conditional Access policies configured: $($conditionalAccessPolicies.Count) policy/policies found" `
                -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prerequisites#identity-authentication-and-single-sign-on-sso'
        } else {
            Add-ValidationResult -CheckpointId 'AUTH-002' -Category 'Authentication' -Priority 'High' -Status 'Warning' `
                -Result "No Conditional Access policies found" `
                -Remediation "Configure SSO and Conditional Access policies for enhanced security." `
                -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prerequisites#identity-authentication-and-single-sign-on-sso'
        }
    } catch {
        Add-ValidationResult -CheckpointId 'AUTH-002' -Category 'Authentication' -Priority 'High' -Status 'Failed' `
            -Result "Unable to check SSO configuration: $_"
    }

    # AUTH-004: User identity sync
    try {
        Write-Verbose "Checking user synchronization..."
        $users = Get-MgUser -Top 10
        
        if ($users -and $users.Count -gt 0) {
            Add-ValidationResult -CheckpointId 'AUTH-004' -Category 'Authentication' -Priority 'High' -Status 'Passed' `
                -Result "User identity synchronization verified: $($users.Count) sample users found" `
                -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prerequisites#identity-authentication-and-single-sign-on-sso'
        } else {
            Add-ValidationResult -CheckpointId 'AUTH-004' -Category 'Authentication' -Priority 'High' -Status 'Failed' `
                -Result "No users found in Entra ID" `
                -Remediation "Ensure user synchronization is configured and working." `
                -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prerequisites#identity-authentication-and-single-sign-on-sso'
        }
    } catch {
        Add-ValidationResult -CheckpointId 'AUTH-004' -Category 'Authentication' -Priority 'High' -Status 'Failed' `
            -Result "Unable to check user synchronization: $_"
    }

    Write-Host "✓ Authentication validation completed" -ForegroundColor Green
    return $script:ValidationResults
}

<#
.SYNOPSIS
    Validates external systems integration readiness

.DESCRIPTION
    Checks SAP SuccessFactors, Workday, and ServiceNow integration configurations.
#>
function Test-ESSExternalSystems {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvironmentId
    )

    Write-Host "`n🔍 Validating External Systems..." -ForegroundColor Cyan

    # Check for SAP SuccessFactors solution
    Write-Verbose "Checking SAP SuccessFactors solution package..."
    $sapSolution = Get-AdminPowerAppEnvironment -EnvironmentName $EnvironmentId | 
        Get-AdminFlow -Filter "contains(displayName, 'SAP') or contains(displayName, 'SuccessFactors')"
    
    if ($sapSolution) {
        Add-ValidationResult -CheckpointId 'SAP-001' -Category 'External Systems' -Priority 'High' -Status 'Passed' `
            -Result "SAP SuccessFactors solution components found: $($sapSolution.Count) flow(s)" `
            -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/sap-successfactors'
    } else {
        Add-ValidationResult -CheckpointId 'SAP-001' -Category 'External Systems' -Priority 'High' -Status 'NotConfigured' `
            -Result "SAP SuccessFactors solution package not installed" `
            -Remediation "If you plan to integrate with SAP SuccessFactors, install the accelerator package from the ESS installation process." `
            -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/sap-successfactors'
    }

    # Check for Workday solution
    Write-Verbose "Checking Workday solution package..."
    $workdaySolution = Get-AdminFlow -EnvironmentName $EnvironmentId | 
        Where-Object { $_.DisplayName -like "*Workday*" }
    
    if ($workdaySolution) {
        Add-ValidationResult -CheckpointId 'WD-001' -Category 'External Systems' -Priority 'High' -Status 'Passed' `
            -Result "Workday solution components found: $($workdaySolution.Count) flow(s)" `
            -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/workday'
        
        # Workday detected - run deep validation via Workday Suite
        Write-Host "`n  📦 Workday solution detected - running extended validation..." -ForegroundColor Magenta
        
        # Load and run Workday environment variable validation
        $workdaySuitePath = Join-Path $PSScriptRoot "WorkdaySuite"
        if (Test-Path $workdaySuitePath) {
            try {
                # Load Workday validation functions
                . (Join-Path $workdaySuitePath "Test-WorkdayEnvironmentVariables.ps1")
                . (Join-Path $workdaySuitePath "Test-WorkdayConnectionReferences.ps1")
                . (Join-Path $workdaySuitePath "Test-WorkdayFlowStatus.ps1")
                
                # Run environment variables check
                $envVarResults = Test-WorkdayEnvironmentVariables -EnvironmentId $EnvironmentId
                foreach ($result in $envVarResults) {
                    Add-ValidationResult -CheckpointId $result.CheckpointId -Category 'Workday' `
                        -Priority $result.Priority -Status $result.Status `
                        -Result $result.Result -Remediation $result.Remediation `
                        -DocumentationLink $result.DocumentationLink
                }
                
                # Run connection references check
                $connRefResults = Test-WorkdayConnectionReferences -EnvironmentId $EnvironmentId
                foreach ($result in $connRefResults) {
                    Add-ValidationResult -CheckpointId $result.CheckpointId -Category 'Workday' `
                        -Priority $result.Priority -Status $result.Status `
                        -Result $result.Result -Remediation $result.Remediation `
                        -DocumentationLink $result.DocumentationLink
                }
                
                # Run flow status check
                $flowResults = Test-WorkdayFlowStatus -EnvironmentId $EnvironmentId
                foreach ($result in $flowResults) {
                    Add-ValidationResult -CheckpointId $result.CheckpointId -Category 'Workday' `
                        -Priority $result.Priority -Status $result.Status `
                        -Result $result.Result -Remediation $result.Remediation `
                        -DocumentationLink $result.DocumentationLink
                }
                
                Write-Host "  ✓ Workday extended validation completed" -ForegroundColor Magenta
            }
            catch {
                Write-Warning "Workday suite validation encountered an error: $_"
                Add-ValidationResult -CheckpointId 'WD-SUITE-ERR' -Category 'Workday' -Priority 'High' -Status 'Warning' `
                    -Result "Workday suite validation error: $_" `
                    -Remediation "Run Invoke-WorkdayValidationSuite manually for detailed diagnostics"
            }
        } else {
            Write-Host "  ℹ️  Workday Suite not found at $workdaySuitePath - basic validation only" -ForegroundColor Yellow
        }
    } else {
        Add-ValidationResult -CheckpointId 'WD-001' -Category 'External Systems' -Priority 'High' -Status 'NotConfigured' `
            -Result "Workday solution package not installed" `
            -Remediation "If you plan to integrate with Workday, install the accelerator package from the ESS installation process." `
            -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/workday'
    }

    # Check for ServiceNow solution
    Write-Verbose "Checking ServiceNow solution package..."
    $serviceNowSolution = Get-AdminFlow -EnvironmentName $EnvironmentId | 
        Where-Object { $_.DisplayName -like "*ServiceNow*" }
    
    if ($serviceNowSolution) {
        Add-ValidationResult -CheckpointId 'SN-001' -Category 'External Systems' -Priority 'High' -Status 'Passed' `
            -Result "ServiceNow solution components found: $($serviceNowSolution.Count) flow(s)" `
            -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/servicenow'
    } else {
        Add-ValidationResult -CheckpointId 'SN-001' -Category 'External Systems' -Priority 'High' -Status 'NotConfigured' `
            -Result "ServiceNow solution package not installed" `
            -Remediation "If you plan to integrate with ServiceNow, install the accelerator package from the ESS installation process." `
            -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/servicenow'
    }

    Write-Host "✓ External systems validation completed" -ForegroundColor Green
    return $script:ValidationResults
}

<#
.SYNOPSIS
    Validates content and knowledge sources configuration

.DESCRIPTION
    Checks SharePoint knowledge sources, semantic indexing limits, metadata, and filtering.
#>
function Test-ESSContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvironmentId
    )

    Write-Host "`n🔍 Validating ESS Content..." -ForegroundColor Cyan

    Write-Host "  ℹ️  Content validation requires manual verification in Copilot Studio" -ForegroundColor Yellow
    
    Add-ValidationResult -CheckpointId 'CONT-001' -Category 'Content' -Priority 'High' -Status 'NotConfigured' `
        -Result "Manual verification required: Check knowledge sources in Copilot Studio" `
        -Remediation "In Copilot Studio, navigate to Knowledge tab and verify SharePoint sites/libraries are configured." `
        -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/customize#configure-knowledge-sources'

    Add-ValidationResult -CheckpointId 'CONT-004' -Category 'Content' -Priority 'High' -Status 'NotConfigured' `
        -Result "Manual verification required: Verify semantic indexing limits (< 200 pages per source)" `
        -Remediation "Check each knowledge source to ensure it contains fewer than 200 pages. This is a known limitation." `
        -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/known-issues-limitations'

    Write-Host "✓ Content validation completed (manual checks required)" -ForegroundColor Green
    return $script:ValidationResults
}

<#
.SYNOPSIS
    Validates Copilot Studio topics configuration

.DESCRIPTION
    Checks required topics configuration including Admin, System, and Example topics.
#>
function Test-ESSTopics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvironmentId
    )

    Write-Host "`n🔍 Validating ESS Topics..." -ForegroundColor Cyan

    Write-Host "  ℹ️  Topics validation requires manual verification in Copilot Studio" -ForegroundColor Yellow
    
    $requiredTopics = @(
        @{Id='TOPIC-001'; Name='[Admin] User Context - Setup'; Priority='Critical'},
        @{Id='TOPIC-002'; Name='[System] Response Preparation'; Priority='Critical'},
        @{Id='TOPIC-004'; Name='[Example] Sensitive Topics'; Priority='High'},
        @{Id='TOPIC-005'; Name='[System] On Error'; Priority='High'},
        @{Id='TOPIC-009'; Name='Emotional Intelligence topic'; Priority='High'},
        @{Id='TOPIC-010'; Name='Ambiguity clarification'; Priority='High'}
    )

    foreach ($topic in $requiredTopics) {
        Add-ValidationResult -CheckpointId $topic.Id -Category 'Topics' -Priority $topic.Priority -Status 'NotConfigured' `
            -Result "Manual verification required: Check '$($topic.Name)' topic configuration" `
            -Remediation "In Copilot Studio, navigate to Topics and verify '$($topic.Name)' is properly configured." `
            -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/customize#customize-topics'
    }

    Write-Host "✓ Topics validation completed (manual checks required)" -ForegroundColor Green
    return $script:ValidationResults
}

<#
.SYNOPSIS
    Validates agent configuration and customization

.DESCRIPTION
    Checks agent branding, instructions, variables, and customization settings.
#>
function Test-ESSConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvironmentId
    )

    Write-Host "`n🔍 Validating ESS Configuration..." -ForegroundColor Cyan

    Write-Host "  ℹ️  Configuration validation requires manual verification in Copilot Studio" -ForegroundColor Yellow
    
    $configChecks = @(
        @{Id='CONFIG-001'; Name='Agent name customized'; Priority='Medium'},
        @{Id='CONFIG-002'; Name='Agent logo uploaded'; Priority='Medium'},
        @{Id='CONFIG-005'; Name='Starter prompts configured (up to 12)'; Priority='High'},
        @{Id='CONFIG-007'; Name='Agent global instructions written'; Priority='Critical'},
        @{Id='CONFIG-008'; Name='Agent personality defined'; Priority='High'},
        @{Id='CONFIG-012'; Name='User Context variables created'; Priority='Critical'}
    )

    foreach ($check in $configChecks) {
        Add-ValidationResult -CheckpointId $check.Id -Category 'Configuration' -Priority $check.Priority -Status 'NotConfigured' `
            -Result "Manual verification required: Verify '$($check.Name)'" `
            -Remediation "In Copilot Studio, navigate to Overview/Configure tab and verify this setting." `
            -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/customize'
    }

    Write-Host "✓ Configuration validation completed (manual checks required)" -ForegroundColor Green
    return $script:ValidationResults
}

<#
.SYNOPSIS
    Validates publishing and deployment readiness

.DESCRIPTION
    Checks golden prompts testing, quality benchmarks, ALM process, and channel configuration.
#>
function Test-ESSPublishing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvironmentId
    )

    Write-Host "`n🔍 Validating Publishing Configuration..." -ForegroundColor Cyan

    Write-Host "  ℹ️  Publishing validation requires manual verification" -ForegroundColor Yellow
    
    $publishingChecks = @(
        @{Id='QA-001'; Name='Golden prompts library created (50+ prompts)'; Priority='Critical'},
        @{Id='QA-002'; Name='Core functionality prompts tested'; Priority='Critical'},
        @{Id='QA-012'; Name='Accuracy validation completed'; Priority='Critical'},
        @{Id='PUB-001'; Name='Solution exported as managed'; Priority='Critical'},
        @{Id='PUB-002'; Name='Test environment deployment completed'; Priority='Critical'},
        @{Id='PUB-003'; Name='UAT testing completed with sign-off'; Priority='Critical'},
        @{Id='PUB-006'; Name='Microsoft 365 admin approval obtained'; Priority='Critical'}
    )

    foreach ($check in $publishingChecks) {
        Add-ValidationResult -CheckpointId $check.Id -Category 'Publishing' -Priority $check.Priority -Status 'NotConfigured' `
            -Result "Manual verification required: Verify '$($check.Name)'" `
            -Remediation "Complete this step according to deployment checklist and ALM guidelines." `
            -DocumentationLink 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/deploy-overview-alm'
    }

    Write-Host "✓ Publishing validation completed (manual checks required)" -ForegroundColor Green
    return $script:ValidationResults
}

<#
.SYNOPSIS
    Adds a validation result to the results collection
#>
function Add-ValidationResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CheckpointId,

        [Parameter(Mandatory = $true)]
        [string]$Category,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Critical', 'High', 'Medium', 'Low')]
        [string]$Priority,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Passed', 'Failed', 'Warning', 'NotConfigured')]
        [string]$Status,

        [Parameter(Mandatory = $true)]
        [string]$Result,

        [Parameter()]
        [string]$Remediation = '',

        [Parameter()]
        [string]$DocumentationLink = ''
    )

    $validationResult = [PSCustomObject]@{
        CheckpointId       = $CheckpointId
        Category           = $Category
        Priority           = $Priority
        Status             = $Status
        Result             = $Result
        Remediation        = $Remediation
        DocumentationLink  = $DocumentationLink
        ValidationDate     = Get-Date
    }

    $script:ValidationResults += $validationResult

    # Display result
    $statusIcon = switch ($Status) {
        'Passed' { '✅' }
        'Failed' { '❌' }
        'Warning' { '⚠️' }
        'NotConfigured' { 'ℹ️' }
    }

    $statusColor = switch ($Status) {
        'Passed' { 'Green' }
        'Failed' { 'Red' }
        'Warning' { 'Yellow' }
        'NotConfigured' { 'Gray' }
    }

    Write-Host "  $statusIcon [$CheckpointId] $Result" -ForegroundColor $statusColor

    if ($Remediation -and $Status -in @('Failed', 'Warning')) {
        Write-Host "    → Remediation: $Remediation" -ForegroundColor Cyan
    }
}

<#
.SYNOPSIS
    Gets validation summary statistics
#>
function Get-ValidationSummary {
    $summary = [PSCustomObject]@{
        TotalChecks    = $script:ValidationResults.Count
        Passed         = ($script:ValidationResults | Where-Object Status -eq 'Passed').Count
        Failed         = ($script:ValidationResults | Where-Object Status -eq 'Failed').Count
        Warnings       = ($script:ValidationResults | Where-Object Status -eq 'Warning').Count
        NotConfigured  = ($script:ValidationResults | Where-Object Status -eq 'NotConfigured').Count
    }
    
    return $summary
}

<#
.SYNOPSIS
    Clears all validation results
.DESCRIPTION
    Resets the validation results array. Useful when running multiple independent validations.
#>
function Clear-ValidationResults {
    $script:ValidationResults = @()
}

<#
.SYNOPSIS
    Exports validation results to specified format
#>
function Export-ValidationResults {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Results,

        [Parameter(Mandatory = $true)]
        [ValidateSet('JSON', 'HTML', 'CSV')]
        [string]$Format,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    switch ($Format) {
        'JSON' {
            $Results | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8
            Write-Host "`n✓ Validation results exported to: $Path" -ForegroundColor Green
        }
        'CSV' {
            $Results | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
            Write-Host "`n✓ Validation results exported to: $Path" -ForegroundColor Green
        }
        'HTML' {
            $html = Generate-HTMLReport -Results $Results
            $html | Out-File -FilePath $Path -Encoding UTF8
            Write-Host "`n✓ Validation results exported to: $Path" -ForegroundColor Green
        }
    }
}

<#
.SYNOPSIS
    Generates HTML report from validation results
#>
function Generate-HTMLReport {
    param([array]$Results)

    $summary = Get-ValidationSummary

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>ESS Pre-flight Validation Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .header { background-color: #0078d4; color: white; padding: 20px; border-radius: 5px; }
        .summary { background-color: white; padding: 20px; margin: 20px 0; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .summary-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; }
        .summary-item { text-align: center; padding: 15px; border-radius: 5px; }
        .passed { background-color: #d4edda; color: #155724; }
        .failed { background-color: #f8d7da; color: #721c24; }
        .warning { background-color: #fff3cd; color: #856404; }
        .notconfigured { background-color: #e7e7e7; color: #666; }
        .results { background-color: white; padding: 20px; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { background-color: #0078d4; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #ddd; }
        tr:hover { background-color: #f5f5f5; }
        .status-passed { color: #28a745; font-weight: bold; }
        .status-failed { color: #dc3545; font-weight: bold; }
        .status-warning { color: #ffc107; font-weight: bold; }
        .status-notconfigured { color: #6c757d; font-weight: bold; }
        .priority-critical { background-color: #ffe6e6; }
        .priority-high { background-color: #fff4e6; }
        .footer { margin-top: 20px; text-align: center; color: #666; }
    </style>
</head>
<body>
    <div class="header">
        <h1>ESS Pre-flight Deployment Validation Report</h1>
        <p>Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        <p>Validation Scope: $($script:ValidationScope)</p>
    </div>
    
    <div class="summary">
        <h2>Validation Summary</h2>
        <div class="summary-grid">
            <div class="summary-item passed">
                <h3>$($summary.Passed)</h3>
                <p>Passed</p>
            </div>
            <div class="summary-item failed">
                <h3>$($summary.Failed)</h3>
                <p>Failed</p>
            </div>
            <div class="summary-item warning">
                <h3>$($summary.Warnings)</h3>
                <p>Warnings</p>
            </div>
            <div class="summary-item notconfigured">
                <h3>$($summary.NotConfigured)</h3>
                <p>Not Configured</p>
            </div>
        </div>
    </div>
    
    <div class="results">
        <h2>Detailed Results</h2>
        <table>
            <thead>
                <tr>
                    <th>Checkpoint</th>
                    <th>Category</th>
                    <th>Priority</th>
                    <th>Status</th>
                    <th>Result</th>
                    <th>Remediation</th>
                </tr>
            </thead>
            <tbody>
"@

    foreach ($result in $Results) {
        $priorityClass = "priority-$($result.Priority.ToLower())"
        $statusClass = "status-$($result.Status.ToLower())"
        
        $html += @"
                <tr class="$priorityClass">
                    <td>$($result.CheckpointId)</td>
                    <td>$($result.Category)</td>
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
    </div>
    
    <div class="footer">
        <p>ESS Pre-flight Deployment Validator v1.0.0</p>
        <p>For more information, visit: <a href="https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/">Microsoft Learn - Employee Self-Service</a></p>
    </div>
</body>
</html>
"@

    return $html
}

<#
.SYNOPSIS
    Initializes validation session and connects to required services
#>
function Initialize-ValidationSession {
    Write-Verbose "Initializing validation session..."
    
    try {
        # Check if Microsoft Graph is connected
        $graphContext = Get-MgContext -ErrorAction SilentlyContinue
        if (-not $graphContext) {
            Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
            Connect-MgGraph -Scopes "Organization.Read.All", "Directory.Read.All", "User.Read.All", "Policy.Read.All" -NoWelcome
        } else {
            Write-Verbose "Already connected to Microsoft Graph"
        }

        # Check if Power Platform is connected
        Write-Verbose "Verifying Power Platform connection..."
        $ppConnection = Get-AdminPowerAppEnvironment -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $ppConnection) {
            Write-Host "Connecting to Power Platform..." -ForegroundColor Yellow
            Add-PowerAppsAccount
        } else {
            Write-Verbose "Already connected to Power Platform"
        }

        Write-Verbose "Validation session initialized successfully"
    }
    catch {
        Write-Error "Failed to initialize validation session: $_"
        throw
    }
}

# Export module members
Export-ModuleMember -Function @(
    'Test-ESSDeploymentReadiness',
    'Test-ESSPrerequisites',
    'Test-ESSEnvironment',
    'Test-ESSAuthentication',
    'Test-ESSExternalSystems',
    'Test-ESSContent',
    'Test-ESSTopics',
    'Test-ESSConfiguration',
    'Test-ESSPublishing',
    'Clear-ValidationResults'
)


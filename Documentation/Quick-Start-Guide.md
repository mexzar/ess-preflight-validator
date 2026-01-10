# ESS Pre-flight Deployment Validator - Quick Start Guide

## Overview

The ESS Pre-flight Deployment Validator provides two validation approaches:
1. **Power Platform Solution** - Automated validation flows within Copilot Studio
2. **PowerShell Module** - Command-line validation scripts

Both solutions validate the same comprehensive set of deployment readiness criteria.

---

## Option 1: Power Platform Solution Setup

### Prerequisites
- Power Platform Administrator access
- Target environment with Dataverse database
- Copilot Studio access

### Installation Steps

1. **Import the Solution**
   ```
   1. Download ESS-PreFlight-Validator solution (managed)
   2. Navigate to Power Platform Admin Center
   3. Select target environment
   4. Go to Solutions > Import
   5. Upload the solution file
   6. Follow the import wizard
   ```

2. **Configure Connections**
   ```
   After import, configure connection references:
   - Microsoft Dataverse
   - Microsoft Graph (for license and role checks)
   - Power Platform for Admins
   ```

3. **Access the Validator Agent**
   ```
   1. Open Copilot Studio
   2. Navigate to Agents
   3. Select "ESS Validation Reporter"
   4. Click "Test your agent" to start validation
   ```

### Running Validation

**Interactive Validation via Agent:**
```
User: "Run full validation"
Agent: Executes comprehensive validation and reports results

User: "Check prerequisites"
Agent: Validates only prerequisite requirements

User: "Show validation results"
Agent: Displays detailed findings with remediation
```

**Programmatic Validation via Flow:**
```
1. Navigate to Power Automate
2. Find "ESS-Orchestrator-Validation" flow
3. Click "Run"
4. Provide inputs:
   - ValidationScope: Full/Prerequisites/Environment/etc.
   - EnvironmentId: Target environment GUID
5. Review results in Dataverse tables
```

### Viewing Results

**In Copilot Studio Agent:**
- Interactive chat interface
- Adaptive cards with issue details
- Direct links to remediation documentation

**In Power Platform:**
1. Navigate to Dataverse tables
2. View "ESS Validation Results" table
3. Filter by Validation Run ID
4. Export to Excel for reporting

---

## Option 2: PowerShell Module Setup

### Prerequisites
- PowerShell 7.0 or higher
- Microsoft.Graph PowerShell module v2.0+
- Microsoft.PowerApps.Administration.PowerShell v2.0+
- Appropriate admin permissions

### Installation Steps

1. **Install Required Modules**
   ```powershell
   # Install Microsoft Graph PowerShell SDK
   Install-Module Microsoft.Graph -Scope CurrentUser -Force

   # Install Power Platform Admin PowerShell
   Install-Module Microsoft.PowerApps.Administration.PowerShell -Scope CurrentUser -Force
   ```

2. **Import the ESS Validator Module**
   ```powershell
   # Navigate to module directory
   cd C:\ESS-PreFlight-Validator\PowerShell

   # Import the module
   Import-Module .\ESS-Validator.psm1 -Force

   # Verify module loaded
   Get-Module ESS-Validator
   ```

3. **Connect to Services**
   ```powershell
   # Connect to Microsoft Graph
   Connect-MgGraph -Scopes "Organization.Read.All", "Directory.Read.All", "User.Read.All", "Policy.Read.All"

   # Connect to Power Platform
   Add-PowerAppsAccount
   ```

### Running Validation

**Full Validation (Recommended for Initial Assessment):**
```powershell
# Run complete validation with verbose output
Test-ESSDeploymentReadiness -Scope Full -Verbose

# Run with JSON export
Test-ESSDeploymentReadiness -Scope Full -OutputFormat JSON -ExportPath "C:\Reports\ess-validation.json"

# Run with HTML report
Test-ESSDeploymentReadiness -Scope Full -OutputFormat HTML -ExportPath "C:\Reports\ess-validation.html"
```

**Targeted Validation (For Specific Areas):**
```powershell
# Prerequisites only
Test-ESSDeploymentReadiness -Scope Prerequisites

# Environment configuration only
Test-ESSDeploymentReadiness -Scope Environment -EnvironmentId "your-environment-guid"

# Authentication only
Test-ESSDeploymentReadiness -Scope Authentication

# External systems only
Test-ESSDeploymentReadiness -Scope ExternalSystems -EnvironmentId "your-environment-guid"

# Content & knowledge sources
Test-ESSDeploymentReadiness -Scope Content -EnvironmentId "your-environment-guid"

# Topics configuration
Test-ESSDeploymentReadiness -Scope Topics -EnvironmentId "your-environment-guid"

# Agent configuration
Test-ESSDeploymentReadiness -Scope Configuration -EnvironmentId "your-environment-guid"

# Publishing readiness
Test-ESSDeploymentReadiness -Scope Publishing -EnvironmentId "your-environment-guid"
```

**Individual Function Calls:**
```powershell
# Run specific validation functions
Test-ESSPrerequisites
Test-ESSEnvironment -EnvironmentId "your-environment-guid"
Test-ESSAuthentication
Test-ESSExternalSystems -EnvironmentId "your-environment-guid"
Test-ESSContent -EnvironmentId "your-environment-guid"
Test-ESSTopics -EnvironmentId "your-environment-guid"
Test-ESSConfiguration -EnvironmentId "your-environment-guid"
Test-ESSPublishing -EnvironmentId "your-environment-guid"
```

### Understanding Results

**Console Output:**
```
🔍 Validating Prerequisites...
  ✅ [PRE-001] Microsoft 365 Copilot licenses found: 150 consumed
  ✅ [PRE-002] Copilot Studio licenses found: COPILOT_STUDIO_USER
  ❌ [PRE-003] No Microsoft Teams licenses found
    → Remediation: Ensure users have Teams licenses if deploying via Teams channel
  ✅ [PRE-008] Global Admin role assigned to 2 user(s)
✓ Prerequisites validation completed

========================================
ESS PRE-FLIGHT VALIDATION SUMMARY
========================================
Validation Scope: Full
Total Checks: 45
Passed: 38 | Failed: 3 | Warnings: 4 | Not Configured: 0
Overall Status: ❌ NOT READY - ISSUES FOUND
========================================
```

**Status Indicators:**
- ✅ **Passed**: Requirement met, no action needed
- ❌ **Failed**: Critical issue, must be resolved
- ⚠️ **Warning**: Non-critical issue, should be addressed
- ℹ️ **Not Configured**: Optional feature not configured

**Priority Levels:**
- **Critical**: Blocker - must pass before deployment
- **High**: Important - requires remediation plan
- **Medium**: Should fix - can deploy with plan to address
- **Low**: Nice-to-have - optional configuration

---

## Usage Examples

### Example 1: Initial Pre-Deployment Assessment

**Scenario:** First-time validation before starting ESS deployment

```powershell
# Run comprehensive validation and export detailed report
Test-ESSDeploymentReadiness -Scope Full -OutputFormat HTML -ExportPath "C:\Reports\ess-initial-assessment.html" -Verbose

# Review the HTML report in browser
Start-Process "C:\Reports\ess-initial-assessment.html"
```

**Expected Actions:**
1. Review all failed and warning items
2. Create remediation plan for critical failures
3. Assign tasks to appropriate teams
4. Re-run validation after fixes

---

### Example 2: Environment Setup Verification

**Scenario:** Verify Power Platform environment is correctly configured

```powershell
# Get your environment ID
$environments = Get-AdminPowerAppEnvironment
$targetEnv = $environments | Out-GridView -Title "Select ESS Environment" -OutputMode Single

# Validate environment configuration
Test-ESSDeploymentReadiness -Scope Environment -EnvironmentId $targetEnv.EnvironmentName -Verbose
```

---

### Example 3: Pre-Publishing Readiness Check

**Scenario:** Final validation before publishing to production

```powershell
# Run full validation before go-live
$results = Test-ESSDeploymentReadiness -Scope Full -EnvironmentId "prod-environment-guid"

# Filter for critical failures only
$criticalFailures = $results | Where-Object { $_.Priority -eq 'Critical' -and $_.Status -eq 'Failed' }

if ($criticalFailures.Count -eq 0) {
    Write-Host "✅ READY FOR PRODUCTION DEPLOYMENT" -ForegroundColor Green
} else {
    Write-Host "❌ CRITICAL ISSUES FOUND - DO NOT DEPLOY" -ForegroundColor Red
    $criticalFailures | Format-Table CheckpointId, Result, Remediation -Wrap
}
```

---

### Example 4: Automated Validation in CI/CD Pipeline

**Scenario:** Integrate validation into Azure DevOps or GitHub Actions

```powershell
# validation-pipeline.ps1

# Connect to services using service principal
$tenantId = $env:AZURE_TENANT_ID
$clientId = $env:AZURE_CLIENT_ID
$clientSecret = $env:AZURE_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force

$credential = New-Object System.Management.Automation.PSCredential($clientId, $clientSecret)

Connect-MgGraph -TenantId $tenantId -ClientSecretCredential $credential

# Run validation
$results = Test-ESSDeploymentReadiness -Scope Full -EnvironmentId $env:TARGET_ENVIRONMENT_ID -OutputFormat JSON -ExportPath "validation-results.json"

# Check for failures
$failures = $results | Where-Object { $_.Status -eq 'Failed' -and $_.Priority -in @('Critical', 'High') }

if ($failures.Count -gt 0) {
    Write-Error "Validation failed with $($failures.Count) critical/high issues"
    exit 1
} else {
    Write-Host "Validation passed - deployment approved"
    exit 0
}
```

**Azure DevOps YAML:**
```yaml
- task: PowerShell@2
  displayName: 'Run ESS Pre-flight Validation'
  inputs:
    filePath: 'scripts/validation-pipeline.ps1'
    pwsh: true
  env:
    AZURE_TENANT_ID: $(TenantId)
    AZURE_CLIENT_ID: $(ClientId)
    AZURE_CLIENT_SECRET: $(ClientSecret)
    TARGET_ENVIRONMENT_ID: $(EnvironmentId)
```

---

### Example 5: Weekly Compliance Check

**Scenario:** Automated weekly validation to detect configuration drift

```powershell
# scheduled-validation.ps1

$reportPath = "C:\Reports\Weekly\ess-validation-$(Get-Date -Format 'yyyy-MM-dd').html"

# Run validation
Test-ESSDeploymentReadiness -Scope Full -EnvironmentId "prod-environment-guid" -OutputFormat HTML -ExportPath $reportPath

# Email report to stakeholders
$params = @{
    From = 'ess-validator@company.com'
    To = 'platform-admins@company.com', 'ess-owners@company.com'
    Subject = "ESS Weekly Validation Report - $(Get-Date -Format 'yyyy-MM-dd')"
    Body = "Attached is the weekly ESS deployment validation report. Please review for any configuration drift or issues."
    Attachments = $reportPath
    SmtpServer = 'smtp.company.com'
}

Send-MailMessage @params
```

**Schedule in Task Scheduler:**
```powershell
$action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument '-File C:\Scripts\scheduled-validation.ps1'
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 9am
$principal = New-ScheduledTaskPrincipal -UserId "DOMAIN\ServiceAccount" -LogonType ServiceAccount
Register-ScheduledTask -TaskName "ESS Weekly Validation" -Action $action -Trigger $trigger -Principal $principal
```

---

### Example 6: Multi-Environment Comparison

**Scenario:** Compare validation results across Dev, Test, and Prod environments

```powershell
# multi-env-validation.ps1

$environments = @{
    'Development' = 'dev-env-guid'
    'Test' = 'test-env-guid'
    'Production' = 'prod-env-guid'
}

$allResults = @()

foreach ($envName in $environments.Keys) {
    Write-Host "`nValidating $envName environment..." -ForegroundColor Cyan
    
    $results = Test-ESSDeploymentReadiness -Scope Full -EnvironmentId $environments[$envName]
    
    # Add environment name to results
    $results | ForEach-Object { 
        $_ | Add-Member -NotePropertyName 'Environment' -NotePropertyValue $envName -PassThru
    }
    
    $allResults += $results
}

# Export combined results
$allResults | Export-Csv -Path "C:\Reports\multi-env-comparison.csv" -NoTypeInformation

# Generate comparison report
$allResults | Group-Object CheckpointId | ForEach-Object {
    [PSCustomObject]@{
        CheckpointId = $_.Name
        Dev_Status = ($_.Group | Where-Object Environment -eq 'Development').Status
        Test_Status = ($_.Group | Where-Object Environment -eq 'Test').Status
        Prod_Status = ($_.Group | Where-Object Environment -eq 'Production').Status
    }
} | Format-Table -AutoSize
```

---

## Interpreting Validation Results

### Result Object Structure

Each validation checkpoint returns an object with the following properties:

```powershell
CheckpointId       : PRE-001
Category           : Prerequisites
Priority           : Critical
Status             : Failed
Result             : No Microsoft 365 Copilot licenses found
Remediation        : Purchase and assign Microsoft 365 Copilot licenses to users...
DocumentationLink  : https://learn.microsoft.com/en-us/copilot/microsoft-365/...
ValidationDate     : 2025-05-15 14:30:00
```

### Status Meanings

| Status | Meaning | Action Required |
|--------|---------|-----------------|
| **Passed** | Requirement met successfully | None - continue deployment |
| **Failed** | Requirement not met | Critical - must fix before deployment |
| **Warning** | Non-critical issue detected | Recommended - create remediation plan |
| **NotConfigured** | Optional feature not set up | Optional - configure if needed |

### Priority Impact on Deployment

| Priority | Failed Status Impact | Deployment Decision |
|----------|---------------------|---------------------|
| **Critical** | Blocks deployment | DO NOT DEPLOY - fix required |
| **High** | Deployment at risk | Requires executive approval & plan |
| **Medium** | Deploy with monitoring | Document as known issue |
| **Low** | No impact | Proceed with deployment |

---

## Remediation Workflow

### Step-by-Step Remediation Process

1. **Run Initial Validation**
   ```powershell
   $results = Test-ESSDeploymentReadiness -Scope Full -EnvironmentId "your-env-guid"
   ```

2. **Identify Critical Failures**
   ```powershell
   $criticalIssues = $results | Where-Object { $_.Status -eq 'Failed' -and $_.Priority -eq 'Critical' }
   $criticalIssues | Format-Table CheckpointId, Result, Remediation -Wrap
   ```

3. **Create Remediation Tickets**
   ```powershell
   $criticalIssues | ForEach-Object {
       # Create work item in Azure DevOps, Jira, etc.
       Write-Host "Create ticket for: $($_.CheckpointId) - $($_.Result)"
       Write-Host "Remediation: $($_.Remediation)"
       Write-Host "Documentation: $($_.DocumentationLink)`n"
   }
   ```

4. **Fix Issues Based on Remediation Guidance**
   - Follow the remediation steps provided
   - Consult documentation links
   - Engage appropriate teams (InfoSec, Platform Admins, etc.)

5. **Re-run Validation for Fixed Items**
   ```powershell
   # Validate specific category after fixes
   Test-ESSDeploymentReadiness -Scope Prerequisites -Verbose
   ```

6. **Repeat Until All Critical Issues Resolved**
   ```powershell
   do {
       $results = Test-ESSDeploymentReadiness -Scope Full -EnvironmentId "your-env-guid"
       $criticalFailures = $results | Where-Object { $_.Status -eq 'Failed' -and $_.Priority -eq 'Critical' }
       
       if ($criticalFailures.Count -gt 0) {
           Write-Host "Still have $($criticalFailures.Count) critical issues" -ForegroundColor Yellow
           Read-Host "Fix issues and press Enter to re-validate"
       }
   } while ($criticalFailures.Count -gt 0)
   
   Write-Host "✅ All critical issues resolved!" -ForegroundColor Green
   ```

---

## Troubleshooting

### Common Issues

**Issue: "Connect-MgGraph fails with authentication error"**
```powershell
# Solution: Use interactive authentication
Connect-MgGraph -Scopes "Organization.Read.All", "Directory.Read.All" -UseDeviceAuthentication

# Or specify tenant
Connect-MgGraph -TenantId "your-tenant-id" -Scopes "Organization.Read.All"
```

**Issue: "Unable to check Power Platform environment"**
```powershell
# Solution: Ensure you're connected and have permissions
Add-PowerAppsAccount -TenantID "your-tenant-id"

# Verify connection
Get-AdminPowerAppEnvironment | Select-Object -First 1
```

**Issue: "Module import fails"**
```powershell
# Solution: Check PowerShell version and module dependencies
$PSVersionTable.PSVersion  # Should be 7.0+

# Update required modules
Update-Module Microsoft.Graph -Force
Update-Module Microsoft.PowerApps.Administration.PowerShell -Force

# Import with force
Import-Module .\ESS-Validator.psm1 -Force -Verbose
```

**Issue: "Validation runs but all checks show NotConfigured"**
```
# Solution: This is expected for manual verification items (Topics, Configuration, Publishing)
# These require manual checks in Copilot Studio as they cannot be validated programmatically
```

---

## Best Practices

### 1. Run Early and Often
- Run initial validation before starting configuration
- Re-run after each major configuration change
- Run full validation before each environment promotion

### 2. Export and Archive Results
```powershell
# Create dated reports
$date = Get-Date -Format 'yyyy-MM-dd-HHmm'
Test-ESSDeploymentReadiness -Scope Full -OutputFormat HTML -ExportPath "Reports\validation-$date.html"
```

### 3. Integrate with ALM Process
- Add validation step in solution export process
- Require validation pass for production promotion
- Include validation reports in change requests

### 4. Use Version Control for Reports
```powershell
# Commit validation results to Git
git add Reports/validation-*.html
git commit -m "Validation results for release v1.2"
```

### 5. Maintain Validation Baselines
- Keep "golden" validation reports for reference
- Compare against baseline to detect drift
- Document accepted warnings/exceptions

---

## Next Steps

After successful validation:

1. ✅ **Address all Critical failures**
2. ✅ **Review and plan for High priority warnings**
3. ✅ **Document Medium/Low items for post-deployment**
4. ✅ **Get stakeholder sign-offs** (use Deployment-Checklists.md)
5. ✅ **Proceed with deployment following ALM process**

---

## Support & Resources

- **Validation Matrix**: See `ValidationMatrix.md` for detailed checkpoint descriptions
- **Deployment Checklists**: See `Deployment-Checklists.md` for comprehensive manual checklists
- **Microsoft Learn**: https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/
- **ESS Validator Issues**: Create issue in your internal repository

---

**Quick Start Guide Version**: 1.0.0  
**Last Updated**: $(Get-Date -Format "yyyy-MM-dd")  
**ESS Pre-flight Deployment Validator**

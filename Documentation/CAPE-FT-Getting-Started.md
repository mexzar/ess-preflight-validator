# ESS Pre-Flight Validator
## Complete Guide for CAPE & FastTrack Teams

**Version:** 1.6.0  
**Release Date:** February 4, 2026  
**Author:** ESS Deployment Team

---

# Table of Contents

1. [Introduction](#introduction)
2. [ESS-Validator Module](#ess-validator-module)
3. [Start-ESSValidation.ps1](#start-essvalidationps1)
4. [Start-ESSDeployment.ps1](#start-essdeploymentps1)
5. [Workday Validation Suite](#workday-validation-suite)
6. [Troubleshooting](#troubleshooting)
7. [Quick Reference](#quick-reference)

---

# Introduction

## What is the ESS Pre-Flight Validator?

The ESS Pre-Flight Validator is a comprehensive PowerShell-based validation toolkit designed to **reduce deployment friction and accelerate time-to-value** for Microsoft 365 Copilot Employee Self-Service (ESS) deployments.

### The Problem It Solves

Before this tool, validating an ESS deployment meant:
- Manually checking 50+ configuration items across multiple portals
- Hours of back-and-forth with customers discovering missing permissions
- No standardized way to verify Workday/ServiceNow/SAP integrations
- Reactive troubleshooting instead of proactive validation

### What It Does

The ESS Pre-Flight Validator provides:

| Capability | Benefit |
|------------|---------|
| **71+ automated validation checks** | Catch issues before they become blockers |
| **Interactive wizard experience** | Guide users through complex validation |
| **HTML report generation** | Share professional reports with stakeholders |
| **Profile save/load** | Don't re-authenticate every session |
| **Workday deep-dive validation** | Test SSO, SOAP APIs, flows, and security domains |
| **ServiceNow flow detection** | Verify HRSD and ITSM components |

### Who Should Use This

- **CAPE Teams** - Pre-engagement validation
- **FastTrack Engineers** - Deployment readiness assessment
- **Customer IT Admins** - Self-service validation (with guidance)
- **Engineering/Support** - ICM investigation support

---

# ESS-Validator Module

## The Foundation of Everything

`ESS-Validator.psm1` is the **core validation engine** that powers all other scripts. Think of it as the brain—every validation script imports this module to access shared functions, validation logic, and reporting capabilities.

## Why First Load Is Slow

When you run any ESS validation script for the first time in a session, you'll notice a 10-15 second delay. This is normal and expected. Here's what's happening:

```
Loading ESS Validation Wizard...
  • Loading validation module...        ← ESS-Validator.psm1
  • Loading Microsoft Graph...          ← Microsoft.Graph module
  • Loading Power Platform...           ← Power Platform admin modules
✓ Ready!
```

**The module loads:**
- Microsoft Graph SDK (for Entra ID, licenses, users)
- Power Platform Administration modules (for environments, flows, connections)
- Custom validation functions (71+ checks)
- Report generation engine

**Subsequent runs in the same PowerShell session are fast** because modules remain loaded in memory.

## What It Validates

The ESS-Validator module contains validation functions organized into categories:

### Prerequisites (PRE-xxx)
| Check ID | What It Validates |
|----------|-------------------|
| PRE-001 | Microsoft 365 Copilot licenses available |
| PRE-002 | Copilot Studio licenses assigned |
| PRE-003 | Microsoft Teams licenses for users |
| PRE-008 | Global Admin role assignments |

### Environment Configuration (ENV-xxx)
| Check ID | What It Validates |
|----------|-------------------|
| ENV-001 | Power Platform environment exists |
| ENV-002 | Dataverse database provisioned |
| ENV-003 | Environment type (Production/Sandbox) |
| ENV-008 | DLP policy configuration |

### Authentication (AUTH-xxx)
| Check ID | What It Validates |
|----------|-------------------|
| AUTH-001 | Microsoft Entra ID configuration |
| AUTH-002 | Conditional Access policies |
| AUTH-004 | User identity synchronization |

### External Systems (WD-xxx, SN-xxx, SAP-xxx)
| Check ID | What It Validates |
|----------|-------------------|
| WD-001 | Workday solution components |
| WD-ENV-xxx | Workday environment variables |
| WD-CONN-xxx | Workday connection references |
| WD-FLOW-xxx | Workday Power Automate flows |
| SN-001 | ServiceNow solution components |
| SAP-001 | SAP SuccessFactors solution |

### Content & Topics (CONT-xxx, TOPIC-xxx)
| Check ID | What It Validates |
|----------|-------------------|
| CONT-001 | Knowledge sources configured |
| CONT-004 | Semantic indexing limits |
| TOPIC-001 | User Context topic setup |
| TOPIC-002 | Response Preparation topic |

### Publishing (PUB-xxx, QA-xxx)
| Check ID | What It Validates |
|----------|-------------------|
| QA-001 | Golden prompts library |
| QA-002 | Core functionality testing |
| PUB-001 | Solution export status |
| PUB-003 | UAT sign-off |

## How to Import Manually

If you need to use validation functions directly:

```powershell
Import-Module "C:\ESS-PreFlight-Validator\PowerShell\ESS-Validator.psm1" -Force
```

---

# Start-ESSValidation.ps1

## The Star of the Show

`Start-ESSValidation.ps1` is the **interactive validation wizard** that brings everything together. This is the script you'll use 90% of the time. It's designed to be impressive—both in capability and presentation.

## What Makes It Special

### 1. Interactive Wizard Experience
No need to remember parameters or syntax. The script guides you through every step:

```
╔════════════════════════════════════════════════════════════════╗
║     ESS Pre-flight Deployment Validation Wizard v1.0           ║
║     Interactive validation for Employee Self-Service           ║
╚════════════════════════════════════════════════════════════════╝

🔍 Detecting your user context...
✓ Detected user: admin@contoso.com

Use this account for validation? [Y/n]: 
```

### 2. Profile Save & Load
The script remembers your previous sessions:

```
✓ Found saved profile: '[PROD] - ESS + Workday - 2026-01-30' (last used 2026-01-30 09:30:00)

Use saved profile? [Y/n]: y
```

This means:
- No re-authentication required
- Environment already selected
- Jump straight to validation

### 3. Smart Environment Discovery
Automatically finds all Power Platform environments you have access to:

```
🌍 Loading Power Platform environments...
✓ Found 86 environment(s)

💡 Tip: You can search in the grid by typing in the search box
Do you know the environment name/ID to search for? [y/N]: y
Enter environment name or ID to search: ESS
✓ Found 3 matching environment(s)
```

### 4. Agent-Scoped Validation
Reduce noise by validating only what your agent uses:

```
🤖 Agent Selection

   Solution-scoped validation checks ONLY the components used by your agent.
   This reduces noise from ~500 checks to ~50.

   ┌─────────────────────────────────────────────────────────┐
   │ [1] Enter agent name                                     │
   │ [2] Skip (full environment scan)                         │
   └─────────────────────────────────────────────────────────┘
```

### 5. Real-Time Progress Display
See what's happening as it runs:

```
[███████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 30% - Running comprehensive validation...
🔍 Validating Prerequisites...
  ✅ [PRE-001] Microsoft 365 Copilot licenses found: 33 consumed out of 50 enabled
  ✅ [PRE-002] Copilot Studio licenses found: Power_Virtual_Agents
  ✅ [PRE-003] Microsoft Teams licenses found: 50 users licensed
```

### 6. HTML Report Export
Professional reports you can share with customers and leadership:

```
✓ Validation results exported to: C:\ESS-Reports\ESS-Validation-20260130-093253.html

Open report in browser? [Y/n]: y
```

## How to Run It

### Step 1: Open PowerShell
Open a PowerShell window (regular PowerShell or VS Code terminal).

### Step 2: Navigate to the Script
```powershell
cd C:\ESS-PreFlight-Validator\PowerShell
```

### Step 3: Run the Script
```powershell
.\Start-ESSValidation.ps1
```

### Step 4: Follow the Wizard
The script will guide you through:
1. Account confirmation
2. Profile selection (if saved)
3. Environment selection
4. Agent selection (optional)
5. Permission check
6. Full validation run
7. Report generation

## Understanding the Output

### Summary Statistics
```
========================================
ESS PRE-FLIGHT VALIDATION SUMMARY
========================================
Validation Scope: Full
Total Checks: 84
Passed: 33 | Failed: 25 | Warnings: 1 | Not Configured: 25
Overall Status: ❌ NOT READY - ISSUES FOUND
========================================
```

### What Each Status Means

| Status | Icon | Meaning | Action |
|--------|------|---------|--------|
| **Passed** | ✅ | Check completed successfully | None required |
| **Failed** | ❌ | Critical issue found | Must fix before deployment |
| **Warning** | ⚠️ | Non-blocking issue | Review and address if possible |
| **Not Configured** | ℹ️ | Requires manual verification | Check in Copilot Studio |

### Common "Not Configured" Items
Some checks cannot be automated and require manual verification in Copilot Studio:
- Knowledge sources configuration
- Topic customizations
- Agent personality settings
- Starter prompts

These appear as "Not Configured" but are not failures—they're reminders to verify manually.

---

# Start-ESSDeployment.ps1

## The Deployment Operator

`Start-ESSDeployment.ps1` is designed for **deployment execution**—when you're ready to go live and need a final checklist.

## When to Use It

| Use Case | Script |
|----------|--------|
| Initial assessment / discovery | `Start-ESSValidation.ps1` |
| Pre-deployment final check | `Start-ESSDeployment.ps1` |
| Ongoing monitoring | `Start-ESSValidation.ps1` |

## Key Differences from Start-ESSValidation

| Aspect | Start-ESSValidation | Start-ESSDeployment |
|--------|---------------------|---------------------|
| Focus | Comprehensive validation | Deployment readiness |
| Depth | 71+ checks | Critical path only |
| Audience | Assessment | Go-live execution |

## How to Run It

```powershell
cd C:\ESS-PreFlight-Validator\PowerShell
.\Start-ESSDeployment.ps1
```

---

# Workday Validation Suite

## The Deep Dive

The Workday Validation Suite is a collection of specialized scripts for validating Workday integration. This section is your **survival guide** for Workday deployments.

## ⚠️ CRITICAL: Prerequisites

Before running any Workday validation, you **MUST** have the correct permissions configured.

### Requirement 1: Entra ID Enterprise App Permissions

The Workday SSO Enterprise Application in Entra ID must grant read permissions for the validation scripts to work.

**Why This Matters:**
- The scripts need to read Workday configuration via Microsoft Graph
- Without this permission, SSO validation will fail
- This is a **read-only** permission—no changes are made

**How to Grant the Permission:**

1. **Open Azure Portal**
   - Navigate to: https://portal.azure.com
   - Go to: Microsoft Entra ID → Enterprise Applications

2. **Find the Workday SSO App**
   - Search for "Workday" in the applications list
   - Select the Workday Single Sign-On application

3. **Add API Permissions**
   - Go to: Permissions → Add a permission
   - Select: Microsoft Graph
   - Choose: Application permissions
   - Add: `Application.Read.All` (read-only)

4. **Grant Admin Consent**
   - Click: "Grant admin consent for [Your Organization]"
   - Confirm the action

**Verification:**
```powershell
# Test that you can read the enterprise app
Connect-MgGraph -Scopes "Application.Read.All"
Get-MgServicePrincipal -Filter "displayName eq 'Workday'"
```

### Requirement 2: Workday ISU Account

You need a valid Integration System User (ISU) account in Workday with appropriate security domain permissions.

**Two Types of ISU Accounts:**

| Account Type | Used For | Security Domains Needed |
|--------------|----------|------------------------|
| **ISU_Generic** | SOAP API calls | Human_Resources, Staffing |
| **ISU_WQL** | Report/RaaS calls | Custom report access |

## Workday Suite Scripts

### Invoke-WorkdayValidationSuite.ps1

**The All-in-One Workday Validator**

This script runs all Workday validations in sequence:

```powershell
cd C:\ESS-PreFlight-Validator\PowerShell\WorkdaySuite
.\Invoke-WorkdayValidationSuite.ps1 -EnvironmentId "your-environment-id"
```

**What It Checks:**
1. Environment Variables (Step 1/4)
2. Connection References (Step 2/4)
3. Flow Status (Step 3/4)
4. Connectivity (Step 4/4)

**Parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-EnvironmentId` | Yes | Power Platform environment GUID |
| `-SkipConnectivityTest` | No | Skip interactive connectivity test |
| `-IncludeSSODiagnostics` | No | Deep SSO analysis |
| `-GenerateChecklist` | No | Export Workday admin checklist |

**Example with All Options:**
```powershell
.\Invoke-WorkdayValidationSuite.ps1 `
    -EnvironmentId "00000000-0000-0000-0000-000000000000" `
    -IncludeSSODiagnostics `
    -GenerateChecklist
```

### Test-WorkdayEnvironmentVariables.ps1

**Validates the Three Critical Environment Variables**

ESS requires three environment variables to be configured in Power Platform:

| Variable | Expected Value | Description |
|----------|----------------|-------------|
| `EmployeeContextRequestAccountName` | Your ISU account | **Must be manually set** |
| `EmployeeContextRequestReportName` | `WD_User_Context` | Auto-populated |
| `EmployeeContextRequestReportInstanceName` | `Report2` | Auto-populated |

**Output Example:**
```
Workday Environment Variables Status:
─────────────────────────────────────────────────────────
⚠️  EmployeeContextRequestAccountName
    Status: Requires manual configuration
    Action: Set to your Workday ISU account name

ℹ️  EmployeeContextRequestReportName
    Expected: 'WD User Context'
    Status: Verify auto-populated value
```

### Test-WorkdayConnectionReferences.ps1

**Validates All Workday SOAP Connections**

This script checks every Workday connection in your environment:

```
✅ Found 44 Workday connection(s)

  ✅ isu wql entra
     Connector: shared_workdaysoap
     Status: Connected
     Created: 10/17/2025 16:47:17

  ❌ Workday SOAP
     Connector: shared_workdaysoap
     Status: Error
     Created: 07/14/2025 06:44:17
```

**Healthy vs Unhealthy Connections:**

| Status | Meaning | Action |
|--------|---------|--------|
| Connected | Working properly | None |
| Error | Authentication failed | Re-authenticate in Power Platform |

**Tip:** Old connections in "Error" state can be deleted to reduce clutter.

### Test-WorkdayFlowStatus.ps1

**Validates Workday Power Automate Flows**

ESS uses Power Automate flows to communicate with Workday:

```
✅ Found 2 Workday-related flow(s)

  ✅ Workday Get User Context
     State: Enabled
     Modified: 01/22/2026 12:10:42

  ✅ Workday
     State: Enabled
     Modified: 01/13/2026 07:50:19

Summary: 2 enabled, 0 disabled
```

**Critical Flows:**
- `Workday Get User Context` - Retrieves employee data
- `Workday` - Main orchestration flow

Both must be **Enabled** for ESS to function.

### Test-WorkdayWorkflows.ps1

**Tests 17 Workday Business Process Permissions**

This script validates that your ISU account can access the required Workday operations:

| Workflow | API | What It Tests |
|----------|-----|---------------|
| Get_Workers | Human_Resources | Employee lookup |
| Get_Organizations | Human_Resources | Org structure |
| Get_Job_Profiles | Staffing | Position data |
| Get_Locations | Human_Resources | Location data |
| ... and 13 more | | |

## Testing via Power Automate Flow

### Why Test via Flow?

If your Workday tenant uses **Entra ID SSO** (Single Sign-On), Basic Authentication from PowerShell will not work. The SSO configuration requires authentication through the Microsoft identity platform.

**The Solution:** Test the actual Power Automate flow that ESS uses.

### Step-by-Step: Testing "Workday Get User Context" Flow

**Step 1: Navigate to Power Automate**
1. Go to: https://make.powerautomate.com
2. Select your ESS environment from the environment picker (top right)

**Step 2: Find the Flow**
1. Click: My flows → Cloud flows
2. Search for: "Workday Get User Context"
3. Click on the flow name to open it

**Step 3: Run a Test**
1. Click: **Test** (top right)
2. Select: **Manually**
3. Click: **Test**
4. When prompted, enter a valid Employee ID (e.g., `21508`)
5. Click: **Run flow**

**Step 4: Check the Results**

✅ **Success looks like this:**
```json
{
    "statusCode": 200,
    "headers": { ... },
    "body": "<?xml version='1.0'?><env:Envelope>...<wd:Worker>..."
}
```

The response will contain XML with employee data:
- Employee ID
- Name
- Position
- Manager
- Organization
- Location

❌ **Failure looks like this:**

| Status Code | Meaning | Action |
|-------------|---------|--------|
| 401 | Authentication failed | ISU credentials incorrect or SSO misconfigured |
| 400 | Bad request | Report name/parameters incorrect |
| 403 | Forbidden | ISU missing security domain permissions |
| 404 | Not found | Report doesn't exist in Workday |

### Interpreting the Flow Response

**Successful Response Contains:**
```xml
<wd:Get_Workers_Response>
  <wd:Response_Results>
    <wd:Total_Results>1</wd:Total_Results>
  </wd:Response_Results>
  <wd:Response_Data>
    <wd:Worker>
      <wd:Worker_Reference wd:Descriptor="John Smith">
        <wd:ID wd:type="Employee_ID">21508</wd:ID>
      </wd:Worker_Reference>
      <wd:Worker_Data>
        <wd:Personal_Data>
          <wd:Name_Data>...</wd:Name_Data>
        </wd:Personal_Data>
        <wd:Employment_Data>...</wd:Employment_Data>
      </wd:Worker_Data>
    </wd:Worker>
  </wd:Response_Data>
</wd:Get_Workers_Response>
```

**Key Data Points to Verify:**
- `Total_Results` = 1 (employee found)
- `Employee_ID` matches input
- `Personal_Data` contains name
- `Employment_Data` contains position/org

---

# Troubleshooting

## Common Issues and Solutions

### Issue: "First load takes forever"

**Cause:** Module imports (Graph, Power Platform) on first run.

**Solution:** This is normal. Subsequent runs in the same session are fast. If consistently slow, check network connectivity to Microsoft services.

---

### Issue: "Export-ModuleMember" errors

**Cause:** Running scripts directly that are designed to be imported as modules.

**Solution:** Use the launcher scripts:
```powershell
.\Start-ESSValidation.ps1    # Correct
.\ESS-Validator.psm1         # Incorrect - this is a module, not a script
```

---

### Issue: "Cannot connect to Power Platform"

**Cause:** Missing permissions or authentication expired.

**Solution:**
1. Ensure you have Power Platform Administrator or Environment Admin role
2. Re-authenticate:
```powershell
Connect-PowerPlatform
```

---

### Issue: "Workday connection shows Error status"

**Cause:** Credentials expired or ISU account disabled.

**Solution:**
1. Go to Power Platform Admin Center
2. Navigate to: Environments → [Your Environment] → Connections
3. Find the Workday connection
4. Click: Edit → Re-authenticate

---

### Issue: "401 Unauthorized" from Workday

**Cause:** Invalid credentials or SSO misconfiguration.

**Solution:**
1. Verify ISU account is active in Workday
2. Check if SSO is enabled—if so, test via Power Automate flow instead
3. Verify the connection is using the correct authentication method

---

### Issue: "400 Bad Request - Report not found"

**Cause:** The WD_User_Context report doesn't exist or is named differently.

**Solution:**
1. In Workday, search for the custom report
2. Verify the report name matches `EmployeeContextRequestReportName` environment variable
3. Ensure the ISU account has access to the report

---

### Issue: "22 connections in Error state"

**Cause:** Old/abandoned test connections from previous configuration attempts.

**Solution:** These can be safely deleted if not in use:
1. Go to Power Platform → Connections
2. Filter by Status: Error
3. Review and delete unused connections

---

# Quick Reference

## Scripts at a Glance

| Script | Purpose | Run Time |
|--------|---------|----------|
| `Start-ESSValidation.ps1` | Full interactive validation | 2-5 min |
| `Start-ESSDeployment.ps1` | Deployment readiness check | 1-2 min |
| `Invoke-WorkdayValidationSuite.ps1` | Workday deep-dive | 30-60 sec |
| `Test-WorkdayWorkflows.ps1` | Test 17 Workday APIs | 20-30 sec |

## Quick Commands

**Run full validation:**
```powershell
cd C:\ESS-PreFlight-Validator\PowerShell
.\Start-ESSValidation.ps1
```

**Run Workday suite only:**
```powershell
cd C:\ESS-PreFlight-Validator\PowerShell\WorkdaySuite
.\Invoke-WorkdayValidationSuite.ps1 -EnvironmentId "your-env-id" -SkipConnectivityTest
```

**Test Workday connectivity with credentials:**
```powershell
$cred = Get-Credential
.\Test-WorkdayConnectivity.ps1 -Credential $cred
```

## Environment IDs

To find your environment ID:
1. Go to: https://admin.powerplatform.microsoft.com
2. Select your environment
3. Copy the GUID from the URL or Details panel

## Getting Help

- **Internal Wiki:** [Link to your internal documentation]
- **Teams Channel:** [ESS Deployment Support]
- **ICM:** Tag with "ESS-Deployment"

---

# Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.6.0 | Feb 4, 2026 | Internal release for CAPE/FT |
| 1.5.0 | Jan 22, 2026 | Workday workflows + SSO diagnostics |
| 1.4.0 | Jan 15, 2026 | HTML report generation |
| 1.3.0 | Jan 8, 2026 | Profile save/load feature |

---

**Document End**

*For questions or feedback, contact the ESS Deployment Team.*

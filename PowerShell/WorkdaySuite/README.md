# Workday Validation Suite

Comprehensive validation tools for Workday integration with Microsoft 365 Copilot Employee Self-Service (ESS) Agent.

## 📁 Suite Contents

| File | Description |
|------|-------------|
| `Invoke-WorkdayValidationSuite.ps1` | Main entry point - runs all Workday validations |
| `Test-WorkdayEnvironmentVariables.ps1` | Validates Dataverse environment variables |
| `Test-WorkdayConnectionReferences.ps1` | Checks Power Platform connection status |
| `Test-WorkdayFlowStatus.ps1` | Validates Power Automate flow status |
| `Test-WorkdayConnectivity.ps1` | Tests Workday RaaS API connectivity (SOAP/WS-Security) |
| `Test-WorkdaySSOConnectivity.ps1` | Tests Azure AD SSO/OAuth delegated access |

## 🚀 Quick Start

### Run Full Workday Validation Suite
```powershell
# From the PowerShell folder
.\WorkdaySuite\Invoke-WorkdayValidationSuite.ps1 -EnvironmentId "your-environment-id"
```

### Run Individual Tests
```powershell
# Check environment variables only
. .\WorkdaySuite\Test-WorkdayEnvironmentVariables.ps1
Test-WorkdayEnvironmentVariables -EnvironmentId "your-environment-id"

# Check connection references only
. .\WorkdaySuite\Test-WorkdayConnectionReferences.ps1
Test-WorkdayConnectionReferences -EnvironmentId "your-environment-id"

# Check flow status only
. .\WorkdaySuite\Test-WorkdayFlowStatus.ps1
Test-WorkdayFlowStatus -EnvironmentId "your-environment-id"

# Test API connectivity (interactive)
.\WorkdaySuite\Test-WorkdayConnectivity.ps1

# Test SSO connectivity (interactive)
.\WorkdaySuite\Test-WorkdaySSOConnectivity.ps1
```

## 📋 Environment Variables Validated

Per [Microsoft Documentation](https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/workday#step-4-environment-variables):

| Variable | Description | Validation |
|----------|-------------|------------|
| `EmployeeContextRequestAccountName` | ISU service account with RaaS access | **CRITICAL** - Must be manually set |
| `EmployeeContextRequestReportName` | RaaS report name | Default: "WD User Context" |
| `EmployeeContextRequestReportInstanceName` | Report instance name | Default: "Report2" |

## 🔌 Integration with Main Validator

The Workday suite integrates with the main ESS Validator:

```powershell
# Full ESS validation (auto-detects and runs Workday checks)
Import-Module .\ESS-Validator.psm1
Test-ESSDeploymentReadiness -EnvironmentId "your-environment-id" -Scope Full
```

When Workday flows are detected, the validator will:
1. ✅ Report Workday solution found (WD-001)
2. 🔗 Validate environment variables (WD-ENV-001 through WD-ENV-003)
3. ⚡ Check flow status (WD-FLOW-xxx)
4. 🌐 Optionally prompt for connectivity test

## 🔐 Prerequisites

- PowerShell 7.0+
- Microsoft.PowerApps.Administration.PowerShell module
- Power Platform Administrator or Environment Admin permissions
- For connectivity tests: Workday ISU credentials

## 📊 Checkpoint IDs

| ID | Category | Description |
|----|----------|-------------|
| WD-001 | External Systems | Workday solution installed |
| WD-ENV-001 | Workday | Account name variable configured |
| WD-ENV-002 | Workday | Report name variable verified |
| WD-ENV-003 | Workday | Report instance variable verified |
| WD-CONN-REF-xxx | Workday | Connection reference status |
| WD-FLOW-xxx | Workday | Flow enabled/disabled status |
| WD-CONN-001 | Workday | API connectivity verified |

## 📚 Documentation

- [Workday Integration Guide](https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/workday)
- [Environment Variables Setup](https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/workday#step-4-environment-variables)
- [Connection References](https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/workday#step-3-connection-references)

---
*Part of ESS Pre-flight Validator v1.2.0*
